# frozen_string_literal: true

Firesport::Series::Team::Base = Struct.new(:round, :team, :team_number) do
  attr_reader :rank

  include Certificates::StorageSupport

  def self.points_for_result(rank, _time, round, gender:, double_rank_count: 0)
    [max_points(round, gender:) + 1 - rank - double_rank_count, 0].max
  end

  def initialize(*args)
    super
    @rank = 0
    @cups ||= {}
  end

  delegate :id, to: :team, prefix: true

  def full_name
    if multi_team?
      "#{team&.name} #{team_number}"
    else
      team&.name.to_s
    end
  end

  def multi_team?
    round.participations.where(team_id:).where.not(team_number:).exists?
  end

  def best_result_entry
    @best_result_entry ||= Score::ResultEntry.new(time_with_valid_calculation: best_time).human_time
  end

  def add_participation(participation)
    @cups ||= {}
    @cups[participation.cup_id] ||= []
    @cups[participation.cup_id].push(participation)
  end

  def participations_for_cup(cup)
    @cups ||= {}
    (@cups[cup.id] || []).sort_by(&:assessment)
  end

  def points_for_cup(cup)
    @cups ||= {}
    @cups[cup.id] ||= []
    @cups[cup.id].sum(&:points)
  end

  def count
    @cups ||= {}
    @cups.values.count
  end

  def points
    @cups.values.sum { |cup| cup.sum(&:points) }
  end

  def best_time
    @best_time ||= @cups.values.flatten.select { |p| p.assessment.discipline == 'la' }.map(&:time).min
  end

  def best_time_without_nil
    best_time || (Firesport::INVALID_TIME + 1)
  end

  def <=>(other)
    other.points <=> points
  end

  def self.special_sort!(_rows); end

  def calculate_rank!(other_rows)
    other_rows.each_with_index do |rank_row, rank|
      return @rank = (rank + 1) if (self <=> rank_row).zero?
    end
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
