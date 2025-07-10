# frozen_string_literal: true

class Firesport::Series::Team::ThueringenCup < Firesport::Series::Team::LaCup
  def self.max_points(*)
    10
  end

  def self.points_for_result(rank, time, round, gender:, double_rank_count: 0)
    if rank == 1
      max_points(round, gender:) - double_rank_count
    elsif rank == 2
      max_points(round, gender:) - 2 - double_rank_count
    else
      super(rank + 2, time, round, gender:, double_rank_count:)
    end
  end

  def <=>(other)
    compare = other.points <=> points
    return compare unless compare.zero?

    compare = best_rank <=> other.best_rank
    return compare unless compare.zero?

    compare = other.best_rank_count <=> best_rank_count
    return compare unless compare.zero?

    compare = other.ordered_participations.count <=> ordered_participations.count
    return compare unless compare.zero?

    sum_time <=> other.sum_time
  end

  protected

  def sum_time
    @sum_time ||= begin
      sum = ordered_participations.sum(&:time)
      [sum, Firesport::INVALID_TIME].min
    end
  end

  def calc_participation_count
    round.full_cup_count
  end
end
