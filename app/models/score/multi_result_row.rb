# frozen_string_literal: true

class Score::MultiResultRow
  include Score::ResultRowSupport

  attr_reader :entity, :result, :result_rows

  delegate :competition, :results, to: :result

  def initialize(entity, result)
    @entity = entity
    @result = result
    @result_rows = []
  end

  def add_result_row(result_row)
    @result_rows.push(result_row)
    @sorted_result_rows = nil
  end

  def best_result_entry
    @best_result_entry ||= Score::ResultEntry.new(time_with_valid_calculation: calculate)
  end

  def assessment_type
    nil
  end

  def valid?
    best_result_entry.result_valid?
  end

  def result_entry
    best_result_entry
  end

  def result_entry_from(result, position: 0)
    entries = sorted_result_rows.find { |row| row.result == result }&.result_entries || []
    entries[position]
  end

  def <=>(other)
    compare = best_result_entry <=> other.best_result_entry
    return compare unless compare.zero?

    i = -1
    loop do
      i += 1
      return 0 if i > 100 # to ensure

      time = calculate(position: i)
      other_time = other.calculate(position: i)

      return 0 if time == Firesport::INVALID_TIME && other_time == Firesport::INVALID_TIME

      compare = time <=> other_time
      next if compare.zero?

      return compare
    end
  end

  protected

  def sorted_result_rows
    @sorted_result_rows ||= result_rows.sort
  end
end
