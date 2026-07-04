# frozen_string_literal: true

module Score::Resultable
  def add_ranks(rows)
    valids, invalids = rows.partition(&:valid?)

    rank = 1
    rank_before = nil
    same = 0

    valids.each_with_index do |row, _index|
      if rank_before && (row <=> rank_before) == 0
        same += 1
      else
        rank += same
        same = 1
      end

      row.rank =  rank
      rank_before = row
    end

    normal_invalids, complete_invalids = invalids.partition(&:competition_result_valid?)

    last_rank = rows.count
    complete_invalids.each { |row| row.rank = last_rank }
    last_rank -= complete_invalids.count
    normal_invalids.each { |row| row.rank = last_rank }
    rows
  end
end
