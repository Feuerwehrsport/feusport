# frozen_string_literal: true

class Competitions::InformationRequestsController < CompetitionNestedController
  default_resource

  def create
    @information_request.assign_attributes(information_request_params)
    if @information_request.valid? && verify_recaptcha(model: @information_request) && @information_request.save
      CompetitionMailer.with(information_request: @information_request).information_request.deliver_later
      redirect_to competition_show_path, notice: 'Die Anfrage wird per E-Mail übermittelt.'
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  protected

  def assign_new_resource
    super
    resource_instance.user = current_user
  end

  def information_request_params
    params.require(:information_request).permit(
      :message,
    )
  end
end
