# frozen_string_literal: true

class Series::Team
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Certificates::StorageSupport

  attr_accessor :config, :team, :team_number, :team_gender, :rank, :round

  delegate :id, to: :team, prefix: true

  def initialize(*)
    @rank = 0
    super
  end

  def full_name
    if multi_team?
      "#{team&.name} #{team_number}"
    else
      team&.name.to_s
    end
  end

  def multi_team?
    round.team_participations.where(team_id:).where.not(team_number:).exists?
  end

  def add_participation(participation)
    @cups ||= {}
    @cups[participation.cup_id] ||= []
    @cups[participation.cup_id].push(participation)
  end

  def participations_for_cup(cup)
    @cups ||= {}
    (@cups[cup.id] || []).sort_by(&:team_assessment)
  end

  def count
    @cups ||= {}
    @cups.values.count
  end

  def all_points
    @cups.values.sum { |cup| cup.sum(&:points_with_correction) }
  end

  def points
    @points ||= begin
      sum = ordered_participations.sum(&:points_with_correction)
      if config.penalty_points.nil?
        sum
      else
        fail_points = (config.round.cups.count - count) * config.penalty_points
        sum + fail_points
      end
    end
  end

  def best_time
    @best_time ||= begin
      scores = @cups.values.flatten
      scores.select! { |p| p.team_assessment.discipline == 'la' } if config.disciplines.include?('la')
      scores.map(&:time).min
    end
  end

  def second_best_time
    best_result_entry
  end

  def second_sum_time
    sum_result_entry
  end

  def best_result_entry
    @best_result_entry ||= Score::ResultEntry.new(time_with_valid_calculation: best_time).human_time
  end

  def sum_result_entry
    @sum_result_entry ||= Score::ResultEntry.new(time_with_valid_calculation: sum_time).human_time
  end

  def best_time_without_nil
    best_time || (Firesport::INVALID_TIME + 1)
  end

  def sum_time
    @sum_time ||= begin
      sum = ordered_participations.sum(&:time)
      [sum, Firesport::INVALID_TIME].min
    end
  end

  def best_rank
    @cups.values.flatten.map(&:rank).min
  end

  def best_rank_count
    @cups.values.flatten.map(&:rank).count { |r| r == best_rank }
  end

  def ordered_participations
    @ordered_participations ||= @cups.values.map(&:first).sort do |a, b|
      compare = b.points_with_correction <=> a.points_with_correction
      compare.zero? ? a.time <=> b.time : compare
    end.first(config.calc_participations_count)
  end

  def valid_participations
    @valid_participations ||= ordered_participations.select { |part| part.time < Firesport::INVALID_TIME }
  end

  def participation_count
    @cups.values.count
  end

  def <=>(other)
    config.sort(self, other)
  end

  def storage_support_get(position)
    case position.key
    when :team_name
      full_name
    when :person_name, :person_bib_number, :assessment_with_gender, :gender, :date, :place, :competition_name
      ''
    when :rank
      "#{rank}."
    when :rank_with_rank
      "#{rank}. Platz"
    when :rank_with_rank2
      "den #{rank}. Platz"
    when :rank_without_dot
      rank.to_s
    when :assessment, :result_name
      round.name
    else
      super
    end
  end
end
