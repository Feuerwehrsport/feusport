# frozen_string_literal: true

class Firesport::Series::Team::SaPokal < Firesport::Series::Team::LaCup
  def self.max_points(_round, gender:)
    gender.to_sym == :male ? 11 : 3 # für 2025
  end

  def calc_participation_count
    round.full_cup_count - 1
  end

  def <=>(other)
    compare = other.points <=> points
    return compare unless compare.zero?

    compare = best_rank <=> other.best_rank
    return compare unless compare.zero?

    compare = other.best_rank_count <=> best_rank_count
    return compare unless compare.zero?

    other.ordered_participations.count <=> ordered_participations.count
  end
end
