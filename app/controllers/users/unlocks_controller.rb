# frozen_string_literal: true

class Users::UnlocksController < Devise::UnlocksController
  # Entsperr-Mails nicht beliebig oft an fremde Adressen auslösen
  rate_limit to: 5, within: 1.minute, only: :create,
             with: -> { redirect_to new_user_unlock_path, alert: :too_many_requests }
end
