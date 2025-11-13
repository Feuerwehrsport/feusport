# frozen_string_literal: true

class Competitions::TeamMarkerValuesController < CompetitionNestedController
  before_action :assign_resource

  def edit
    return unless params[:output] == 'modal'

    render json: { content: render_to_string(partial: 'edit_form') }
  end

  def update
    @team_marker_value.assign_attributes(team_marker_value_params)
    if @team_marker_value.save
      if params[:return_to] == 'team'
        redirect_to competition_team_path(id: @team_marker_value.team_id), notice: :saved
      else
        redirect_to competition_teams_path, notice: :saved
      end
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  protected

  def assign_resource
    team_marker = @competition.team_markers.find(params[:id])
    team = @competition.teams.find(params[:team_id])
    @team_marker_value = TeamMarkerValue.find_or_initialize_by(team_marker:, team:)
  end

  def team_marker_value_params
    return {} unless params.key?(:team_marker_value)

    params.require(:team_marker_value).permit(
      :boolean_value, :date_value, :string_value
    )
  end
end
