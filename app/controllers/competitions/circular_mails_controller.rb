# frozen_string_literal: true

class Competitions::CircularMailsController < CompetitionNestedController
  default_resource

  def create
    @circular_mail.assign_attributes(circular_mail_params)
    if @circular_mail.valid? && verify_recaptcha(model: @circular_mail) && @circular_mail.save
      CompetitionMailer.with(circular_mail: @circular_mail).circular_mail.deliver_later
      redirect_to competition_show_path,
                  notice: "Die Rundmail wird an #{@circular_mail.recipients_count} Empfänger verschickt."
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

  def circular_mail_params
    params.require(:circular_mail).permit(:subject, :message)
  end
end
