# frozen_string_literal: true

module Score::ResultsHelper
  include Exports::ScoreResults

  def row_invalid_class(row)
    row.valid? ? '' : 'danger'
  end

  def calculation_method_options
    Score::Result::CALCULATION_METHODS
      .map { |k, _v| [t("score_calculation_methods.#{k}"), k] }
  end

  # Spaltenkopf einer Startliste, nicht öffentliche Listen (nur in der Admin-Ansicht sichtbar) markiert
  def result_list_column_label(list)
    return list.shortcut if list.results_public?

    safe_join([list.shortcut, ' ', tag.i(class: 'far fa-eye-slash', title: 'Nicht öffentlich')])
  end

  def multi_result_method_options
    Score::Result::MULTI_RESULT_METHODS
      .except(:disabled)
      .map { |k, _v| [t("multi_result_methods.#{k}"), k] }
  end
end
