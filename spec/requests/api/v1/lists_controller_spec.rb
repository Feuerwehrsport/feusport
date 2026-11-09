# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::ListsController do
  let(:competition) { create(:competition) }
  let(:access) { ApiAccess.create!(competition:, name: 'Uhr') }
  let!(:list) { create(:score_list, competition:, name: 'Lauf A', separate_target_times: true) }
  let!(:hidden_list) { create(:score_list, competition:, name: 'Versteckt', hidden: true) }
  let(:headers) { api_headers(access) }

  describe 'authentication' do
    it 'rejects missing and wrong tokens' do
      get '/api/v1/lists'
      expect_documented(401)
      expect(json['error']).to eq 'invalid_token'

      get '/api/v1/lists', headers: { 'Authorization' => 'Bearer wrong' }
      expect_documented(401)
    end

    it 'rejects tokens of locked and past competitions' do
      headers
      competition.update!(locked_at: Time.current)
      get('/api/v1/lists', headers:)
      expect_documented(401)

      competition.update!(locked_at: nil)
      travel_to(8.days.from_now) { get('/api/v1/lists', headers:) }
      expect_documented(401)
    end

    it 'records the usage only once per minute' do
      get('/api/v1/lists', headers:)
      used_at = access.reload.last_used_at
      expect(used_at).to be_present

      travel_to(30.seconds.from_now) { get('/api/v1/lists', headers:) }
      expect(access.reload.last_used_at).to eq used_at
    end
  end

  describe 'GET index' do
    it 'returns only visible lists' do
      get('/api/v1/lists', headers:)
      expect_documented(200)
      expect(json['lists']).to eq [{ 'id' => list.id, 'name' => 'Lauf A', 'track_count' => 2,
                                     'separate_target_times' => true }]
    end

    it 'returns only selected lists, also hidden ones' do
      access.update!(permission: :selected_results, score_list_ids: [hidden_list.id])
      get('/api/v1/lists', headers:)
      expect(json['lists'].pluck('id')).to eq [hidden_list.id]
    end

    it 'does not show lists of other competitions' do
      other_list = create(:score_list, competition: create(:competition))
      get("/api/v1/lists/#{other_list.id}", headers:)
      expect_documented(404)
    end
  end

  describe 'GET show' do
    let(:assessment) { list.assessments.first }
    let(:person) { create(:person, :with_team, competition:, band: assessment.band) }
    let!(:entry) { create(:score_list_entry, list:, competition:, assessment:, entity: person, run: 1) }
    let!(:second_entry) { create(:score_list_entry, list:, competition:, assessment:, entity: person, run: 2) }

    it 'returns the entries' do
      get("/api/v1/lists/#{list.id}", headers:)
      expect_documented(200)
      expect(json['entries'].pluck('id')).to eq [entry.id, second_entry.id]
      expect(json['entries'].first).to include('name' => person.full_name, 'band' => assessment.band.name,
                                               'run' => 1, 'track' => 1, 'result_type' => 'waiting', 'time' => nil)
    end

    it 'filters by run' do
      get("/api/v1/lists/#{list.id}", params: { run: 2 }, headers:)
      expect_documented(200)
      expect(json['entries'].pluck('id')).to eq [second_entry.id]
    end

    it 'hides lists that are not accessible' do
      get("/api/v1/lists/#{hidden_list.id}", headers:)
      expect_documented(404)
    end
  end
end
