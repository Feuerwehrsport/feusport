# frozen_string_literal: true

class Score::MultiResultBestRow < Score::MultiResultRow
  def self.select(rows)
    rows.select { |row| row.result_rows.count == row.results.count }
  end

  def add_result_row(result_row)
    super

    @list_entries ||= {}
    result_row.list_entries.each { |list_entry| @list_entries[list_entry.id] = list_entry }
    @sorted_list_entries = nil
  end

  def calculate(position: 0)
    time = (sorted_list_entries[position] || Score::ResultEntry.invalid).compare_time
    Score::ResultEntry.new(time_with_valid_calculation: time).compare_time
  end

  protected

  def sorted_list_entries
    @sorted_list_entries ||= @list_entries&.values&.sort || []
  end
end
