# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'suggestions' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  describe 'GET teams' do
    let!(:team) { create(:fire_sport_statistics_team) }

    it 'returns teams' do
      post '/fire_sport_statistics/suggestions/teams'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.parsed_body).to eq([{ 'id' => team.id, 'name' => 'Mecklenburg-Vorpommern',
                                            'short' => 'Team MV' }])

      post '/fire_sport_statistics/suggestions/teams', params: { name: 'mv' }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.parsed_body).to eq([{ 'id' => team.id, 'name' => 'Mecklenburg-Vorpommern',
                                            'short' => 'Team MV' }])

      post '/fire_sport_statistics/suggestions/teams', params: { name: 'foo' }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.parsed_body).to eq([])
    end
  end

  describe 'GET people' do
    let!(:person) { create(:fire_sport_statistics_person) }

    it 'returns people' do
      post '/fire_sport_statistics/suggestions/people'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.parsed_body).to eq([{ 'first_name' => 'Alfred',
                                            'gender' => 'male',
                                            'id' => person.id,
                                            'last_name' => 'Meier',
                                            'teams' => [] }])

      post '/fire_sport_statistics/suggestions/people', params: { name: 'alfred' }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.parsed_body).to eq([{ 'first_name' => 'Alfred',
                                            'gender' => 'male',
                                            'id' => person.id,
                                            'last_name' => 'Meier',
                                            'teams' => [] }])

      post '/fire_sport_statistics/suggestions/people', params: { name: 'alfred', team_name: 'mv' }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.parsed_body).to eq([{ 'first_name' => 'Alfred',
                                            'gender' => 'male',
                                            'id' => person.id,
                                            'last_name' => 'Meier',
                                            'teams' => [] }])

      post '/fire_sport_statistics/suggestions/people', params: { name: 'peter' }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.parsed_body).to eq([])
    end
  end

  describe 'input handling' do
    let!(:person) { create(:fire_sport_statistics_person) }
    let!(:team) { create(:fire_sport_statistics_team) }

    it 'ignores non-string params' do
      post '/fire_sport_statistics/suggestions/people',
           params: { name: ['alfred'], team_name: { a: 'mv' }, gender: ['male'], real_gender: { a: 'male' } }
      expect(response).to have_http_status(:success)
      expect(response.parsed_body.pluck('id')).to eq [person.id]

      post '/fire_sport_statistics/suggestions/teams', params: { name: { a: 'mv' } }
      expect(response).to have_http_status(:success)
      expect(response.parsed_body.pluck('id')).to eq [team.id]
    end

    it 'truncates long input' do
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        post '/fire_sport_statistics/suggestions/people', params: { name: 'q' * 1000 }
      end
      expect(response).to have_http_status(:success)
      expect(queries.join.count('q')).to be_between(100, 200)
    end

    it 'searches like wildcards literally' do
      post '/fire_sport_statistics/suggestions/people', params: { name: '%' }
      expect(response.parsed_body).to eq []

      post '/fire_sport_statistics/suggestions/teams', params: { name: '_' }
      expect(response.parsed_body).to eq []
    end

    it 'limits requests' do
      store = ActiveSupport::Cache::MemoryStore.new
      allow(FireSportStatistics::SuggestionsController.cache_store).to receive(:increment) do |*args, **opts|
        store.increment(*args, **opts)
      end

      100.times { post '/fire_sport_statistics/suggestions/people', params: { name: 'alfred' } }
      expect(response.parsed_body.pluck('id')).to eq [person.id]

      post '/fire_sport_statistics/suggestions/people', params: { name: 'alfred' }
      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to eq []
    end
  end
end
