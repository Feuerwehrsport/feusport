# frozen_string_literal: true

class Competitions::TeamMarkerBlockValuesController < CompetitionNestedController
  before_action :assign_resources

  def edit; end

  def update
    @team_marker_block_value.assign_attributes(team_marker_block_value_params)
    if @team_marker_block_value.save
      redirect_to competition_teams_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  protected

  def team_marker_block_value_params
    return {} unless params.key?(:team_marker_block_value)

    params.require(:team_marker_block_value).permit(team_marker_values_attributes: %i[
                                                      id boolean_value date_value string_value team_id team_marker_id
                                                    ])
  end

  def assign_resources
    @team_marker_block_value = TeamMarkerBlockValue.new(band: @competition.bands.find(params[:band_id]))
    authorize!(:manage, @team_marker_block_value)

    redirect_to competition_teams_path if @team_marker_block_value.teams.blank?
  end
end
