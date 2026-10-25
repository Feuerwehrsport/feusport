# frozen_string_literal: true

class ApplicationCable::Connection < ActionCable::Connection::Base
  identified_by :current_user

  def connect
    self.current_user = find_user
  end

  # Für den Gastzugang (SimpleAccess.from_session), nur lesend: ein WebSocket kann kein Cookie schreiben
  delegate :session, to: :request

  private

  # Devise (z. B. timeoutable bei abgelaufener Session) wirft :warden. Bei HTTP fängt das die
  # Warden-Middleware, hier nicht – dann gilt die Verbindung wie bei HTTP als nicht angemeldet.
  def find_user
    user = nil
    catch(:warden) { user = env['warden']&.user }
    user
  end
end
