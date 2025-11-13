# frozen_string_literal: true

class Competitions::Certificates::ListsController < CompetitionNestedController
  before_action :assign_new_resource

  def export
    @certificates_list.assign_attributes(certificates_list_params)
    if request.format.pdf? && @certificates_list.valid?
      send_pdf(Exports::Pdf::Certificates::Export) do
        [
          @certificates_list.template,
          "Urkunden: #{@certificates_list.result.name}",
          @certificates_list.rows,
          @certificates_list.background_image,
        ]
      end
    else
      redirect_to action: :new
    end
  end

  def create
    @certificates_list.assign_attributes(certificates_list_params)
    if @certificates_list.save
      redirect_to export_competition_certificates_lists_path(
        certificates_list: {
          template_id: @certificates_list.template_id,
          background_image: @certificates_list.background_image,
          score_result_id: @certificates_list.score_result_id,
          competition_result_id: @certificates_list.competition_result_id,
          group_score_result_id: @certificates_list.group_score_result_id,
          series_team_round_id: @certificates_list.series_team_round_id,
          series_person_assessment_id: @certificates_list.series_person_assessment_id,
        },
        format: :pdf,
      )
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  protected

  def certificates_list_params
    params.require(:certificates_list)
          .permit(:template_id, :background_image, :score_result_id, :competition_result_id, :group_score_result_id,
                  :series_team_round_id, :series_person_assessment_id)
  end

  def assign_new_resource
    @certificates_list = Certificates::List.new(competition: @competition)
    @certificates_list.score_result_id              = params[:score_result_id]
    @certificates_list.competition_result_id        = params[:competition_result_id]
    @certificates_list.series_team_round_id         = params[:series_team_round_id]
    @certificates_list.series_person_assessment_id  = params[:series_person_assessment_id]
    authorize!(:show, @certificates_list)

    rounds = Series::Round.exists_for(@competition).order(:year, :name)
    @series_team_rounds = []
    rounds.each do |round|
      Genderable::KEYS.each do |gender|
        next if round.team_assessment_rows(@competition, gender).blank?

        @series_team_rounds.push(["#{round.name} #{t("gender.#{gender}")}", "#{round.id}-#{gender}"])
      end
    end

    @series_person_assessments = Series::PersonAssessment.where(round: rounds)
  end
end
