# frozen_string_literal: true

class Competitions::UserTeamAccessRequestsController < CompetitionNestedController
  before_action :assign_team
  default_resource resource_class: UserTeamAccessRequest, through_association: :user_team_access_requests
  skip_authorize_resource :competition, only: :connect

  def create
    @user_team_access_request.assign_attributes(user_team_access_request_params)
    if @user_team_access_request.save
      CompetitionMailer.with(user_team_access_request: @user_team_access_request).user_team_access_request.deliver_later
      redirect_to competition_team_accesses_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def destroy
    @user_team_access_request.destroy
    redirect_to competition_team_accesses_path, notice: :deleted
  end

  def connect
    authorize!(:connect, @user_team_access_request)

    if @user_team_access_request.sender == current_user
      flash[:alert] = 'Du kannst dich nicht selber hinzufügen.'
      redirect_to competition_team_accesses_path
    elsif current_user.in?(@user_team_access_request.team.users)
      flash[:alert] = 'Du hast bereits Zugriff auf diese Mannschaft.'
      redirect_to competition_team_accesses_path
    else
      @user_team_access_request.connect(current_user)
      CompetitionMailer.with(sender: @user_team_access_request.sender, user: current_user,
                             competition: @user_team_access_request.competition, team: @user_team_access_request.team)
                       .user_team_access_request_connected.deliver_later
      redirect_to competition_team_path(id: @team.id), notice: 'Du wurdest erfolgreich mit dieser Mannschaft verbunden.'
    end
  end

  protected

  def assign_new_resource
    super

    resource_instance.sender = current_user
    resource_instance.team = @team
    name = ''

    @possible_friends = current_user.friends - @team.users

    selected_friend = @possible_friends.find { |f| f.id == params[:friend_id] }
    if selected_friend
      resource_instance.email = selected_friend.email

      name = " #{selected_friend.name}"
    end

    resource_instance.text = I18n.t('user_team_access_requests.example_text', name:, current: current_user.name,
                                                                              team_name: @team.full_name)
  end

  def user_team_access_request_params
    params.require(:user_team_access_request).permit(
      :email, :text
    )
  end

  def assign_team
    @team = Team.find(params[:team_id])
  end
end
