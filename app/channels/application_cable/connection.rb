# frozen_string_literal: true

class ApplicationCable::Connection < ActionCable::Connection::Base
  identified_by :current_user

  def connect
    self.current_user = env['warden']&.user
  end

  # Für den Gastzugang (SimpleAccess.from_session), nur lesend: ein WebSocket kann kein Cookie schreiben
  delegate :session, to: :request
end
