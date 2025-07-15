# frozen_string_literal: true

module Score::Resultable
  def add_places
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

    last_place = rows.count
    invalids.each { |row| row.place = last_place }
  end
end
