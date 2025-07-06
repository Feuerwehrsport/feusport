# frozen_string_literal: true

Score::ResultRow = Struct.new(:entity, :result) do
  include Score::ResultRowSupport
  attr_reader :list_entries

  delegate :calculation_method, :competition, to: :result

  def add_list(list_entry)
    @list_entries ||= []
    @list_entries.push(list_entry)
  end

  def assessment_type
    @list_entries.first.assessment_type
  end

  def best_result_entry
    @best_result_entry ||=
      case calculation_method
      when 'sum_of_two'
        Score::ResultEntry.new(
          time_with_valid_calculation: result_entries.select(&:result_valid?).first(2).sum(&:compare_time),
        )
      else
        result_entries.first
      end
  end

  def result_entry
    best_result_entry
  end

  def result_entry_from(list)
    @list_entries.select { |entry| entry.list == list }.min
  end

  def result_entries
    @result_entries ||= @list_entries.reject(&:result_waiting?).sort
  end

  def valid?
    @valid ||= result_entries.any?(&:result_valid?)
  end

  def competition_result_valid?
    true
  end

  def display
    "#{entity.full_name} (#{result_entry.long_human_time})"
  end

  def <=>(other)
    case calculation_method
    when 'sum_of_two'
      times = [result_entries.count(&:result_valid?), 2].min
      other_times = [other.result_entries.count(&:result_valid?), 2].min
      if times == other_times
        best_result_entry <=> other.best_result_entry
      else
        other_times <=> times
      end
    else
      both = [result_entries, other.result_entries].map(&:count)
      (0..(both.min - 1)).each do |i|
        compare = result_entries[i] <=> other.result_entries[i]
        next if compare.zero?

        return compare
      end
      both.last <=> both.first
    end
  end
end
