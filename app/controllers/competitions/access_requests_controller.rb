# frozen_string_literal: true

class Competitions::AccessRequestsController < CompetitionNestedController
  default_resource resource_class: UserAccessRequest, through_association: :user_access_requests
  skip_authorization_check only: :connect

  def create
    @access_request.assign_attributes(access_request_params)
    if @access_request.save
      redirect_to competition_accesses_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_entity
    end
  end

  def destroy
    @access_request.destroy
    redirect_to competition_accesses_path, notice: :deleted
  end

  def connect
    authorize!(:connect, @access_request)

    if @access_request.sender == current_user
      flash[:alert] = 'Du kannst dich nicht selber hinzufügen.'
      redirect_to competition_accesses_path
    elsif current_user.in?(@access_request.competition.users)
      flash[:alert] = 'Du hast bereits Zugriff auf diesen Wettkampf.'
      redirect_to competition_accesses_path
    else
      @access_request.connect(current_user)
      redirect_to competition_accesses_path, notice: 'Du wurdest erfolgreich mit dem Wettkampf verbunden.'
    end
  end

  protected

  def assign_new_resource
    super
    resource_instance.sender = current_user
    resource_instance.text = I18n.t('user_access_requests.example_text') + "\n#{current_user.name}"
  end

  def access_request_params
    params.require(:user_access_request).permit(
      :email, :text, :drop_myself
    )
  end
end
