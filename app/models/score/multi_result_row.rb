# frozen_string_literal: true

Score::MultiResultRow = Struct.new(:entity, :result) do
  include Certificates::StorageSupport
  delegate :competition, to: :result
  attr_reader :result_rows

  def add_result_row(result_row)
    @result_rows ||= []
    @result_rows.push(result_row)
  end

  def best_result_entry
    @best_result_entry ||= Score::ResultEntry.new(time_with_valid_calculation: calculate)
  end

  def calculate(position: 0)
    times = result_rows.map { |row| (row.result_entries[position] || Score::ResultEntry.invalid).compare_time }
    return times.sum if result.multi_result_method_sum_of_best?
    return times.min if result.multi_result_method_best?

    Score::ResultEntry.invalid.compare_time
  end

  def assessment_type
    nil
  end

  def result_entry
    best_result_entry
  end

  def result_entry_from(result, position: 0)
    entries = result_rows.find { |row| row.result == result }&.result_entries || []
    entries[position]
  end

  def <=>(other)
    compare = best_result_entry <=> other.best_result_entry
    return compare if compare != 0

    both = [
      result_rows.map { |rr| rr.result_entries.count }.min,
      other.result_rows.map { |rr| rr.result_entries.count }.min,
    ]
    (1..(both.max - 1)).each do |i|
      compare = calculate(position: i) <=> other.calculate(position: i)
      next if compare.zero?

      return compare
    end
    both.last <=> both.first
  end

  def result_rows
    @result_rows.presence || []
  end

  protected

  def climbing_hook_ladder_time
    time_by_discipline('hl')
  end

  def obstacle_course_time
    time_by_discipline('hb')
  end

  def time_by_discipline(discipline_key)
    result_rows.find { |row| row.result.discipline.key == discipline_key }&.best_result_entry
  end
end
