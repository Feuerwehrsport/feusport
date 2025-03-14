# frozen_string_literal: true

Score::GroupResultRow = Struct.new(:team, :score_count, :run_count, :result) do
  include Certificates::StorageSupport
  delegate :competition, to: :result

  def entity
    team
  end

  def add_result_row(result_row)
    @result_rows ||= []
    @result_rows.push(result_row)
  end

  def result_entry
    calculate
    Score::ResultEntry.new(time_with_valid_calculation: @time)
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
    @result_rows.count.between?(score_count, run_count)
  end

  def valid_compare
    competition_result_valid? ? 0 : 1
  end

  def <=>(other)
    compare = valid_compare <=> other.valid_compare
    compare.zero? ? result_entry <=> other.result_entry : compare
  end

  protected

  def calculate
    return if @calculated

    @time = 0
    @rows_in = []
    @rows_out = []
    @result_rows ||= []
    unless competition_result_valid?
      @time = nil
      return
    end
    queue = @result_rows.sort
    (1..score_count).each do
      current = queue.shift
      if current.nil? || !current.best_result_entry.result_valid?
        @time = nil
      else
        @time += current.best_result_entry.time
      end
      @rows_in.push(current) if current.present?
    end
    (score_count + 1..run_count).each do
      current = queue.shift
      @rows_out.push(current) if current.present?
    end
    @calculated = true
  end
end
