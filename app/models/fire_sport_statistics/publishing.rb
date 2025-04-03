# frozen_string_literal: true

require 'net/http'

class FireSportStatistics::Publishing < ApplicationRecord
  belongs_to :competition, class_name: '::Competition'
  belongs_to :user

  schema_validations

  after_create { FireSportStatistics::Publishing::Worker.perform_later }

  class Worker < ApplicationJob
    retry_on Errno::ECONNRESET, EOFError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED, SocketError, Net::ReadTimeout,
             wait: :polynomially_longer, attempts: 8

    def perform
      FireSportStatistics::Publishing.where(published_at: nil).find_each(&:publish!)
    end
  end

  def publish!
    return false unless valid?

    cookies = login

    response = conn.post('/api/import_requests', { 'import_request[compressed_data]': export_data }.to_query,
                         'Cookie' => cookies)

    raise SocketError, 'Publishing failed' unless response.code == '200'

    update!(published_at: Time.current)
  end

  def export_data
    Exports::FullDump.new(competition, user, hint).to_export_data
  end

  def login
    response = conn.post('/api/api_users', { 'api_user[name]': competition.name }.to_query)
    raise SocketError, 'Login failed' unless response.code == '200'

    response.get_fields('set-cookie').map { |cookie| cookie.split('; ')[0] }.join('; ')
  end

  def conn
    @conn ||= begin
      http = Net::HTTP.new('feuerwehrsport-statistik.de', 443)
      http.use_ssl = true
      http
    end
  end
end
