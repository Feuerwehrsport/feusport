# frozen_string_literal: true

class Score::MultiResultSumOfBestRow < Score::MultiResultRow
  def self.select(rows)
    rows.select { |row| row.result_rows.count == row.results.count }
  end

  def calculate(position: 0)
    time = results.sum do |current_result|
      (result_entry_from(current_result, position:) || Score::ResultEntry.invalid).compare_time
    end
    Score::ResultEntry.new(time_with_valid_calculation: time).compare_time
  end
end
