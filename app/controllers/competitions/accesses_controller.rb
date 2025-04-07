# frozen_string_literal: true

class Competitions::AccessesController < CompetitionNestedController
  default_resource resource_class: UserAccess, through_association: :user_accesses

  def edit
    if params[:registration_mail_info] == 'true'
      resource_instance.update(registration_mail_info: true)
    elsif params[:registration_mail_info] == 'false'
      resource_instance.update(registration_mail_info: false)
    end
    redirect_to action: :index
  end
end
