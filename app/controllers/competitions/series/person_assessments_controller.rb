# frozen_string_literal: true

class Competitions::Series::PersonAssessmentsController < CompetitionNestedController
  def show
    @config = Series::AssessmentConfig.find_by_round_key(params[:id], :person)

    send_pdf(Exports::Pdf::Series::PersonAssessment, args: [@config, @competition]) && return

    @page_title = "#{config.round_full_name} - Wettkampfserie"
  end
end
