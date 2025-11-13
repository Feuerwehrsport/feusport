# frozen_string_literal: true

class Competitions::TeamMarkersController < CompetitionNestedController
  default_resource

  def create
    @team_marker.assign_attributes(team_marker_params)
    if @team_marker.save
      redirect_to competition_team_markers_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @team_marker.assign_attributes(team_marker_params)
    if @team_marker.save
      redirect_to competition_team_markers_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @team_marker.destroy
    redirect_to competition_team_markers_path, notice: :deleted
  end

  protected

  def team_marker_params
    return {} unless params.key?(:team_marker)

    params.require(:team_marker).permit(
      :name, :value_type
    )
  end
end
