# frozen_string_literal: true

# == Schema Information
#
# Table name: fire_sport_statistics_publishings
#
#  id             :uuid             not null, primary key
#  hint           :text
#  published_at   :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  user_id        :uuid             not null
#
# Indexes
#
#  index_fire_sport_statistics_publishings_on_competition_id  (competition_id)
#  index_fire_sport_statistics_publishings_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (user_id => users.id)
#
require 'net/http'

class FireSportStatistics::Publishing < ApplicationRecord
  belongs_to :competition, class_name: '::Competition', touch: true
  belongs_to :user

  schema_validations

  after_create { FireSportStatistics::Publishing::Worker.perform_later }

  # Falscher oder fehlender Token. Steht bewusst nicht in `retry_on`: Wiederholen hilft nicht, der Job soll in
  # Mission Control als fehlgeschlagen sichtbar werden.
  class AuthenticationError < StandardError; end

  # Die Statistik hat die Daten mit HTTP 200, aber `"success": false` abgelehnt (z. B. ungültige Daten). Ebenfalls
  # nicht in `retry_on`.
  class RejectedError < StandardError; end

  class Worker < ApplicationJob
    retry_on Errno::ECONNRESET, EOFError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED, SocketError, Net::ReadTimeout,
             wait: :polynomially_longer, attempts: 8

    def perform
      FireSportStatistics::Publishing.where(published_at: nil).find_each(&:publish!)
    end
  end

  def publish!
    return false unless valid?

    token = Rails.configuration.x.feuerwehrsport_statistik[:token]
    raise AuthenticationError, 'FEUERWEHRSPORT_STATISTIK_TOKEN fehlt' if token.blank?

    response = conn.post('/api/import_requests', { 'import_request[compressed_data]': export_data }.to_query,
                         'Authorization' => "Bearer #{token}")

    raise AuthenticationError, "Token abgelehnt (HTTP #{response.code})" if %w[401 403].include?(response.code)
    raise SocketError, 'Publishing failed' unless response.code == '200'

    result = JSON.parse(response.body)
    raise RejectedError, result['message'].presence || 'Übertragung abgelehnt' unless result['success'] == true

    update!(published_at: Time.current)
  end

  def export_data
    Exports::FullDump.new(competition, user, hint).to_export_data
  end

  def conn
    @conn ||= begin
      uri = URI.parse(Rails.configuration.x.feuerwehrsport_statistik[:url])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http
    end
  end
end
