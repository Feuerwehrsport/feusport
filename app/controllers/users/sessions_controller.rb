# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_authorization_check
  # Bremst Passwort-Raten und das gezielte Sperren fremder Konten (Lockable sperrt nach 20 Fehlversuchen)
  rate_limit to: 10, within: 1.minute, only: :create,
             with: -> { redirect_to new_user_session_path, alert: :too_many_requests }

  protected

  def after_sign_in_path_for(_user)
    before_url = session.delete(:requested_url_before_login)
    return before_url if before_url.present?

    super
  end
end
