# frozen_string_literal: true

class Firesport::Series::Person::SaPokal < Firesport::Series::Person::Base
  def self.max_points(*)
    20
  end

  def sum_time
    @sum_time ||= ordered_participations.sum(&:time)
  end

  def points
    @points ||= ordered_participations.sum(&:points)
  end

  def <=>(other)
    compare = other.max_count <=> max_count
    return compare unless compare.zero?

    compare = other.points <=> points
    return compare unless compare.zero?

    compare = sum_time <=> other.sum_time
    return compare unless compare.zero?

    best_time <=> other.best_time
  end

  def max_count
    @max_count ||= [count, 3].min
  end

  protected

  def ordered_participations
    @ordered_participations ||= @participations.sort do |a, b|
      compare = b.points <=> a.points
      compare.zero? ? a.time <=> b.time : compare
    end.first(3)
  end
end
