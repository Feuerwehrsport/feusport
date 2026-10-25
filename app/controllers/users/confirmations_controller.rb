# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # Bestätigungs-Mails nicht beliebig oft an fremde Adressen auslösen
  rate_limit to: 5, within: 1.minute, only: :create,
             with: -> { redirect_to new_user_confirmation_path, alert: :too_many_requests }
end
