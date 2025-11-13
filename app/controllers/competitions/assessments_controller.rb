# frozen_string_literal: true

class Competitions::AssessmentsController < CompetitionNestedController
  default_resource

  def index
    send_pdf(Exports::Pdf::Assessments, args: [@competition])
    send_xlsx(Exports::Xlsx::Assessments, args: [@competition])
  end

  def create
    @assessment.assign_attributes(assessment_params)
    if params[:name_preview]
      @assessment.forced_name = nil
      render json: { name: @assessment.name }
    elsif @assessment.save
      redirect_to competition_assessments_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @assessment.assign_attributes(assessment_params)
    if params[:name_preview]
      @assessment.forced_name = nil
      render json: { name: @assessment.name }
    elsif @assessment.save
      redirect_to competition_assessments_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @assessment.destroy
    redirect_to competition_assessments_path, notice: :deleted
  end

  protected

  def assessment_params
    params.require(:assessment).permit(
      :forced_name, :discipline_id, :band_id, :generate_score_result
    )
  end
end
