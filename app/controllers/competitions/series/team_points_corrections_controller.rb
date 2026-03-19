# frozen_string_literal: true

class Competitions::Series::TeamPointsCorrectionsController < CompetitionNestedController
  default_resource resource_class: Series::TeamPointsCorrection, through_association: :series_team_points_corrections

  def index; end

  def edit; end

  def create
    @team_points_correction.assign_attributes(team_points_correction_params)
    if @team_points_correction.save
      redirect_to competition_series_team_points_corrections_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @team_points_correction.assign_attributes(team_points_correction_params)
    if @team_points_correction.save
      redirect_to competition_series_team_points_corrections_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @team_points_correction.destroy
    redirect_to competition_series_team_points_corrections_path, notice: :deleted
  end

  protected

  def team_points_correction_params
    params.require(:series_team_points_correction).permit(
      :discipline, :round_key, :team_id, :team_number, :points_correction, :points_correction_hint
    )
  end

  def pdf_support?
    false
  end

  def xlsx_support?
    false
  end
end
