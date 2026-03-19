# frozen_string_literal: true

class Competitions::Series::PersonPointsCorrectionsController < CompetitionNestedController
  default_resource resource_class: Series::PersonPointsCorrection,
                   through_association: :series_person_points_corrections

  def index; end

  def edit; end

  def create
    @person_points_correction.assign_attributes(person_points_correction_params)
    if @person_points_correction.save
      redirect_to competition_series_person_points_corrections_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @person_points_correction.assign_attributes(person_points_correction_params)
    if @person_points_correction.save
      redirect_to competition_series_person_points_corrections_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @person_points_correction.destroy
    redirect_to competition_series_person_points_corrections_path, notice: :deleted
  end

  protected

  def person_points_correction_params
    params.require(:series_person_points_correction).permit(
      :round_key, :person_id, :points_correction, :points_correction_hint
    )
  end

  def pdf_support?
    false
  end

  def xlsx_support?
    false
  end
end
