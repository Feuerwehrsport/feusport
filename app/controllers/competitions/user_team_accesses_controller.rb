# frozen_string_literal: true

class Competitions::UserTeamAccessesController < CompetitionNestedController
  before_action :assign_team
  before_action :preauthorize

  def destroy
    if resource_instance.user == current_user
      redirect_to competition_team_accesses_path
    else
      CompetitionMailer.with(competition: @competition, user: resource_instance.user, team: resource_instance.team,
                             actor: current_user).user_team_access_deleted.deliver_later
      resource_instance.destroy
      redirect_to competition_team_accesses_path, notice: :deleted
    end
  end

  protected

  def preauthorize
    authorize!(params[:action].to_sym, UserTeamAccess.new(competition: @competition, team: @team))
  end

  def resource_class
    UserTeamAccess
  end
  helper_method :resource_class

  def resource_collection
    @resource_collection ||= @competition.user_team_accesses.where(team: @team).select do |access|
      can?(params[:action].to_sym, access)
    end
  end
  helper_method :resource_collection

  def assign_team
    @team = @competition.teams.find(params[:team_id])
  end

  def resource_instance
    @resource_instance ||= resource_collection.find { |access| access.id == params[:id] }
  end
  helper_method :resource_instance
end
