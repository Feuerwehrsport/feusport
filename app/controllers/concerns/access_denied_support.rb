# frozen_string_literal: true

module AccessDeniedSupport
  extend ActiveSupport::Concern

  included do
    rescue_from CanCan::AccessDenied do |exception|
      if Rails.env.development?
        # :nocov:
        Rails.logger.warn '### Access Denied'
        Rails.logger.warn exception.inspect
        # :nocov:
      end
      if current_user
        flash[:alert] = 'Zugriff verweigert'
        redirect_to root_path
      else
        flash[:alert] = 'Bitte melde Dich an, um diese Funktion nutzen zu können.'
        session[:requested_url_before_login] = request.fullpath if request.format == :html

        redirect_params = {}
        if (exception.action == :create && exception.subject.is_a?(Competition)) || exception.subject == Competition
          redirect_params[:info_hint] =
            :competition
        end
        redirect_to new_user_session_path(redirect_params)
      end
    end
  end

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: 'Not authorized'
  end
end
