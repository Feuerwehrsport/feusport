# frozen_string_literal: true

Firesport::Series::Person::Base = Struct.new(:round, :entity) do
  attr_reader :participations, :rank

  include Certificates::StorageSupport

  def self.max_points(*)
    30
  end

  def self.points_for_result(rank, _time, round, gender:, double_rank_count: 0)
    [max_points(round, gender:) + 1 - rank - double_rank_count, 0].max
  end

  def initialize(*args)
    super
    @participations ||= []
  end

  def add_participation(participation)
    @participations ||= []
    @participations.push(participation)
  end

  def participation_for_cup(cup)
    @participations.find { |participation| participation.cup == cup }
  end

  def points
    @points ||= @participations.sum(&:points)
  end

  def best_time
    @best_time ||= @participations.map(&:time).min
  end

  def best_result_entry
    @best_result_entry ||= Score::ResultEntry.new(time_with_valid_calculation: best_time).human_time
  end

  def sum_result_entry
    @sum_result_entry ||= Score::ResultEntry.new(time_with_valid_calculation: sum_time).human_time
  end

  def sum_time
    @sum_time ||= @participations.sum(&:time)
  end

  def count
    @count ||= @participations.count
  end

  def <=>(other)
    compare = other.points <=> points
    return compare unless compare.zero?

    compare = other.count <=> count
    return compare unless compare.zero?

    sum_time <=> other.sum_time
  end

  def calculate_rank!(other_rows)
    other_rows.each_with_index do |rank_row, rank|
      return @rank = (rank + 1) if (self <=> rank_row).zero?
    end
  end

  def storage_support_get(position)
    case position.key
    when :person_name
      entity&.full_name
    when :team_name, :person_bib_number, :assessment_with_gender, :gender, :date, :place, :competition_name
      ''
    when :rank
      "#{rank}."
    when :rank_with_rank
      "#{rank}. Platz"
    when :rank_with_rank2
      "den #{rank}. Platz"
    when :rank_without_dot
      rank.to_s
    when :assessment
      participations.first&.assessment&.name
    when :result_name
      round.name
    else
      super
    end
  end
end
