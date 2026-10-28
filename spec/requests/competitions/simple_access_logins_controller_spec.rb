# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::SimpleAccessLoginsController do
  let!(:competition) { create(:competition, visible: true) }

  before { SimpleAccess.create!(competition:, name: 'test', password: 'secret123') }

  def login(password: 'secret123')
    post competition_nested('simple_access_login'), params: { simple_access_login: { name: 'test', password: } }
  end

  describe 'POST simple_access_login' do
    it 'fails with wrong password' do
      post competition_nested('simple_access_login'),
           params: { simple_access_login: { name: 'test', password: 'wrong' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to eq :check_errors
      expect(session.key?("simple_access_#{competition.id}")).to be false
    end

    it 'fails with unknown name' do
      post competition_nested('simple_access_login'),
           params: { simple_access_login: { name: 'unknown', password: 'secret123' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(session.key?("simple_access_#{competition.id}")).to be false
    end

    it 'limits login attempts' do
      store = ActiveSupport::Cache::MemoryStore.new
      allow(described_class.cache_store).to receive(:increment) { |*args, **opts| store.increment(*args, **opts) }

      10.times do
        login(password: 'wrong')
        expect(response).to have_http_status(:unprocessable_content)
      end

      login
      expect(response).to redirect_to(competition_nested('simple_access_login/new'))
      expect(flash[:alert]).to eq :too_many_requests
      expect(session.key?("simple_access_#{competition.id}")).to be false
    end
  end

  describe 'guest session' do
    it 'expires after one hour without requests' do
      login

      travel_to(50.minutes.from_now) do
        get competition_nested('editing/edit')
        expect(response).to have_http_status(:success)
      end

      travel_to(100.minutes.from_now) do
        get competition_nested('editing/edit')
        expect(response).to have_http_status(:success)
      end

      travel_to(161.minutes.from_now) do
        get competition_nested('editing/edit')
        expect_access_denied
        expect(session.key?("simple_access_#{competition.id}")).to be false
      end
    end
  end

  describe 'guest abilities' do
    let(:other_competition) { create(:competition, name: 'Vorlage') }

    before { login }

    it 'allows editing the competition' do
      get competition_nested('editing/edit')
      expect(response).to have_http_status(:success)
    end

    it 'denies deleting, visibility, publishing and duplication' do
      get competition_nested('deletion/new')
      expect_access_denied

      get competition_nested('visibility/edit')
      expect_access_denied

      get competition_nested('publishing/new')
      expect_access_denied

      get competition_nested("duplication/new?duplication[duplicate_from_id]=#{other_competition.id}")
      expect_access_denied
    end
  end
end
