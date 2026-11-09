# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::PairingsController do
  let(:competition) { create(:competition) }
  let(:access) { ApiAccess.create!(competition:, name: 'Uhr') }

  def pair(code = access.pairing_code)
    post '/api/v1/pairings', params: { code:, device_name: 'Stoppuhr 1' }, as: :json
  end

  it 'exchanges the code for a token' do
    pair
    expect_documented(201)
    expect(json['competition']['id']).to eq competition.id

    access.reload
    expect(access).to be_paired
    expect(access.device_name).to eq 'Stoppuhr 1'
    expect(ApiAccess.authenticate(json['token'])).to eq access
  end

  it 'accepts a code only once' do
    code = access.pairing_code
    pair(code)
    expect_documented(201)
    pair(code)
    expect_documented(401)
    expect(json['error']).to eq 'invalid_code'
  end

  it 'rejects unknown, empty and expired codes' do
    pair('00000000')
    expect_documented(401)

    post '/api/v1/pairings', params: {}, as: :json
    expect(response).to have_http_status(:unauthorized)

    code = access.pairing_code
    travel_to(16.minutes.from_now) { pair(code) }
    expect_documented(401)
  end

  it 'rejects locked competitions' do
    code = access.pairing_code
    competition.update!(locked_at: Time.current)
    pair(code)
    expect_documented(401)
  end

  it 'answers malformed json with an error' do
    post '/api/v1/pairings', params: '{', headers: { 'Content-Type' => 'application/json' }
    expect(response).to have_http_status(:bad_request)
    expect(json['error']).to eq 'invalid_json'
  end

  it 'limits attempts' do
    store = ActiveSupport::Cache::MemoryStore.new
    allow(described_class.cache_store).to receive(:increment) { |*args, **opts| store.increment(*args, **opts) }

    10.times do
      pair('00000000')
      expect(response).to have_http_status(:unauthorized)
    end

    pair('00000000')
    expect_documented(429)
  end
end
