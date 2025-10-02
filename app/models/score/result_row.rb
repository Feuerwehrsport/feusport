# frozen_string_literal: true

Score::ResultRow = Struct.new(:entity, :result, :group_result) do
  include Score::ResultRowSupport

  attr_reader :list_entries

  delegate :calculation_method, :competition, :single_discipline?, :like_fire_relay?, to: :result

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

  def starting_time_required?
    @starting_time_required == true
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

      # für die Mindestanzahl der Versuche durchgehen
      (0..(both.min - 1)).each do |i|
        compare = result_entries[i] <=> other.result_entries[i]
        next if compare.zero? # nächster Versuch, da dieser gleich

        return compare # Einer war besser
      end

      # Jetzt sind alle Versuche gleich

      # Wer hat mehr Versuche?
      compare = both.last <=> both.first
      return compare unless compare.zero?

      # Die gleiche Anzahl der Versuche

      # Beide alle Versuche ungültig?
      return 0 unless result_entries[0].result_valid? # dann beide gleich schlecht

      # Einzeldisziplin => Gleichstand
      return 0 if single_discipline?

      # Staffel und Gesamtwertung => Gleichstand
      return 0 if group_result && like_fire_relay?

      # Gruppendisziplin => Wer war zuerst dran

      # Wenn die gleiche Liste, dann anhand der Startposition
      if result_entries[0].list == other.result_entries[0].list
        return result_entries[0].matrix_index <=> other.result_entries[0].matrix_index
      end

      # Ansonsten die zeitliche Reihenfolge der Liste
      starting_time = result_entries[0].list.starting_time
      other_starting_time = other.result_entries[0].list.starting_time
      if starting_time.nil? || other_starting_time.nil?
        @starting_time_required = true
        0
      else
        starting_time <=> other_starting_time
      end
    end
  end
end
