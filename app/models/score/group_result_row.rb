# frozen_string_literal: true

Score::GroupResultRow = Struct.new(:team, :score_count, :run_count, :result) do
  include Score::ResultRowSupport
  delegate :competition, to: :result

  def entity
    team
  end

  def add_result_row(result_row)
    @result_rows ||= []
    @result_rows.push(result_row)
  end

  def result_entry
    best_sum = calculate
    time = best_sum[:valid_count] < score_count ? Firesport::INVALID_TIME : best_sum[:time]
    Score::ResultEntry.new(time_with_valid_calculation: time)
  end

  def rows_in
    calculate
    @rows_in
  end

  def rows_out
    calculate
    @rows_out
  end

  def valid?
    result_entry.result_valid?
  end

  # Zeigt an, ob es generell gültig ist
  # Ungültig, wenn zu viele oder zu wenige gestartet sind
  def competition_result_valid?
    @competition_result_valid ||= @result_rows.count.between?(score_count, run_count)
  end

  def valid_compare
    competition_result_valid? ? 0 : 1
  end

  def <=>(other)
    compare = valid_compare <=> other.valid_compare
    return compare unless compare.zero?

    i = -1
    loop do
      i += 1
      return 0 if i > 100 # to ensure

      sum = calculate(position: i)
      other_sum = other.calculate(position: i)

      compare_valid_count = other_sum[:valid_count] <=> sum[:valid_count]

      return compare_valid_count unless compare_valid_count.zero?

      compare = sum[:time] <=> other_sum[:time]
      next if compare.zero?

      return compare
    end
  end

  protected

  def calculate(position: 0)
    @calculated ||= begin
      @result_rows ||= []
      @result_rows.sort!
      @rows_in = @result_rows[0..(score_count - 1)] || []
      @rows_out = @result_rows[score_count..(run_count - 1)] || []
      {}
    end

    return { time: Firesport::INVALID_TIME, valid_count: 0 } unless competition_result_valid?

    @calculated[position] ||= {
      time: @rows_in.sum { |row| row.result_entries[position]&.time || 0 },
      valid_count: @rows_in.count { |row| row.result_entries[position]&.result_valid? || false },
    }
  end
end
