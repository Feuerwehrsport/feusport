# frozen_string_literal: true

def generate_series_person_participations(h)
  h.map do |key, values|
    aggr = described_class.new(nil, key)
    values.each do |value|
      aggr.add_participation(Series::PersonParticipation.new(points: value.first, time: value.last))
    end
    aggr
  end
end

def generate_series_team_participations(h, year: Date.current.year)
  h.map do |key, values|
    aggr = described_class.new(instance_double(Series::Round, full_cup_count: 3, year:), key)
    values.each do |value|
      aggr.add_participation(Series::TeamParticipation.new(points: value.first, time: value.last))
    end
    aggr
  end
end
