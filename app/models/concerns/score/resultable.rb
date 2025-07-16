# frozen_string_literal: true

module Score::Resultable
  def add_places(rows)
    valids, invalids = rows.partition(&:valid?)

    place = 1
    place_before = nil
    same = 0

    valids.each_with_index do |row, _index|
      if place_before && (row <=> place_before) == 0
        same += 1
      else
        place += same
        same = 1
      end

      row.place =  place
      place_before = row
    end

    normal_invalids, complete_invalids = invalids.partition(&:competition_result_valid?)

    last_place = rows.count
    complete_invalids.each { |row| row.place = last_place }
    last_place -= complete_invalids.count
    normal_invalids.each { |row| row.place = last_place }
    rows
  end
end
