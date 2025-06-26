# frozen_string_literal: true

class Competitions::TeamListRestrictionsController < CompetitionNestedController
  default_resource

  def create
    @team_list_restriction.assign_attributes(team_list_restriction_params)
    if @team_list_restriction.save
      redirect_to competition_team_list_restrictions_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_entity
    end
  end

  def update
    @team_list_restriction.assign_attributes(team_list_restriction_params)
    if @team_list_restriction.save
      redirect_to competition_team_list_restrictions_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team_list_restriction.destroy
    redirect_to competition_team_list_restrictions_path, notice: :deleted
  end

  protected

  def team_list_restriction_params
    return {} unless params.key?(:team_list_restriction)

    params.require(:team_list_restriction).permit(
      :discipline_id, :team1_id, :team2_id, :restriction
    )
  end

  def assign_new_resource
    super
    resource_instance.discipline = @competition.disciplines.first if @competition.disciplines.one?
    resource_instance.team1 = @competition.teams.find_by(id: params[:team1_id]) if params[:team1_id].present?
  end
end
