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
require 'rails_helper'

RSpec.describe FireSportStatistics::Publishing do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:publishing) { described_class.create!(competition:, user:, hint: 'Hinweis') }
  let(:http) { instance_double(Net::HTTP) }
  let(:import_response) { instance_double(Net::HTTPResponse, code: import_status, body: import_body) }
  let(:import_status) { '200' }
  let(:import_body) { '{"success":true,"login":false,"created_id":123}' }
  let(:token) { 'geheimer-token' }

  before do
    allow(Rails.configuration.x).to receive(:feuerwehrsport_statistik)
      .and_return(url: 'https://feuerwehrsport-statistik.de', token:)
    allow(Net::HTTP).to receive(:new).with('feuerwehrsport-statistik.de', 443).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:post).with('/api/import_requests', anything, 'Authorization' => 'Bearer geheimer-token')
                                 .and_return(import_response)
  end

  it 'enqueues worker after create' do
    expect { publishing }.to have_enqueued_job(FireSportStatistics::Publishing::Worker)
  end

  describe '#conn' do
    it 'builds connection with ssl for https url' do
      expect(publishing.conn).to eq http
      expect(http).to have_received(:use_ssl=).with(true)
      publishing.conn
      expect(Net::HTTP).to have_received(:new).once
    end
  end

  describe '#export_data' do
    it 'returns compressed full dump' do
      data = JSON.parse(Zlib::Inflate.inflate(Base64.decode64(publishing.export_data)))
      expect(data).to be_a(Hash)
    end
  end

  describe '#publish!' do
    it 'sends import request with token' do
      expect(publishing.publish!).to be true
      expect(publishing.reload.published_at).to be_within(1.minute).of(Time.current)
      expect(http).to have_received(:post).with(
        '/api/import_requests',
        { 'import_request[compressed_data]': publishing.export_data }.to_query,
        'Authorization' => 'Bearer geheimer-token',
      )
    end

    context 'when publishing is invalid' do
      it 'returns false without requests' do
        publishing.user = nil
        expect(publishing.publish!).to be false
        expect(http).not_to have_received(:post)
      end
    end

    context 'when token is missing' do
      let(:token) { nil }

      it 'raises error without requests' do
        expect { publishing.publish! }.to raise_error(described_class::AuthenticationError, /TOKEN fehlt/)
        expect(http).not_to have_received(:post)
        expect(publishing.reload.published_at).to be_nil
      end
    end

    context 'when statistics rejects data' do
      let(:import_body) { '{"success":false,"message":"Ungültige Daten"}' }

      it 'raises rejected error with message' do
        expect { publishing.publish! }.to raise_error(described_class::RejectedError, 'Ungültige Daten')
        expect(publishing.reload.published_at).to be_nil
      end
    end

    context 'when statistics rejects data without message' do
      let(:import_body) { '{"success":false}' }

      it 'raises rejected error with default message' do
        expect { publishing.publish! }.to raise_error(described_class::RejectedError, 'Übertragung abgelehnt')
        expect(publishing.reload.published_at).to be_nil
      end
    end

    %w[401 403].each do |status|
      context "when token is rejected with #{status}" do
        let(:import_status) { status }
        let(:import_body) { '{"success":false,"message":"Invalid token"}' }

        it 'raises authentication error' do
          expect { publishing.publish! }.to raise_error(described_class::AuthenticationError, /HTTP #{status}/)
          expect(publishing.reload.published_at).to be_nil
        end
      end
    end

    context 'when import fails' do
      let(:import_status) { '500' }

      it 'raises error' do
        expect { publishing.publish! }.to raise_error(SocketError, 'Publishing failed')
        expect(publishing.reload.published_at).to be_nil
      end
    end
  end

  describe 'Worker' do
    it 'publishes all unpublished publishings' do
      publishing
      already = described_class.create!(competition:, user:, published_at: 1.day.ago)

      FireSportStatistics::Publishing::Worker.perform_now

      expect(publishing.reload.published_at).to be_present
      expect(already.reload.published_at).to be < 1.hour.ago
      expect(http).to have_received(:post).with('/api/import_requests', anything, anything).once
    end
  end
end
