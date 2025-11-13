# frozen_string_literal: true

class Competitions::TeamImportsController < CompetitionNestedController
  before_action :assign_new_resource

  def create
    @team_import.assign_attributes(team_import_params)
    if @team_import.save
      redirect_to competition_teams_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  protected

  def team_import_params
    params.require(:team_import).permit(
      :band_id, :import_rows
    )
  end

  def assign_new_resource
    @team_import = TeamImport.new(competition: @competition)
  end
end
