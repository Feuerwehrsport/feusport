# frozen_string_literal: true

class Competitions::TeamDeletionsController < CompetitionNestedController
  before_action :assign_new_resource, only: %i[new create]
  def new; end

  def create
    @team_deletion.assign_attributes(team_deletion_params)
    if @team_deletion.save
      redirect_to competition_teams_path, notice: :deleted
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_entity
    end
  end

  protected

  def assign_new_resource
    @team = @competition.teams.find(params[:id])
    authorize!(:delete, @team)
    @team_deletion = TeamDeletion.new(competition: @competition, team: @team)
  end

  def team_deletion_params
    return {} unless params.key?(:team_deletion)

    params.require(:team_deletion).permit(:confirm, :delete_people)
  end
end
