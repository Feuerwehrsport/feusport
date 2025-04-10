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

  def multi_result_method_options
    Score::Result::MULTI_RESULT_METHODS
      .except(:disabled)
      .map { |k, _v| [t("multi_result_methods.#{k}"), k] }
  end
end
