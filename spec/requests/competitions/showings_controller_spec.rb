# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/visibilities' do
  describe 'edit visibilities' do
    let!(:competition) { create(:competition, visible: false) }
    let!(:user) { competition.users.first }
    let!(:other_user) { create(:user, :other) }

    it 'uses CRUD' do
      get "/#{competition.year}/#{competition.slug}"
      expect(response).to redirect_to '/users/sign_in'
      expect(flash[:alert]).to eq 'Bitte melden Dich an, um diese Funktion nutzen zu können.'
      expect(session[:requested_url_before_login]).to eq '/2024/mv-cup'

      get '/competitions/creations/new'
      expect(response).to redirect_to '/users/sign_in?info_hint=competition'
      expect(flash[:alert]).to eq 'Bitte melden Dich an, um diese Funktion nutzen zu können.'
      expect(session[:requested_url_before_login]).to eq '/competitions/creations/new'

      sign_in other_user

      get "/#{competition.year}/#{competition.slug}"
      expect(response).to redirect_to '/'
      expect(flash[:alert]).to eq 'Zugriff verweigert'
    end
  end

  describe 'simple_access_login' do
    let!(:competition) { create(:competition, visible: true) }

    it 'logs in and out' do
      access = SimpleAccess.create!(competition:, name: 'test', password: 'secret')

      get "/#{competition.year}/#{competition.slug}"
      expect(response).to match_html_fixture.with_affix('with-login-link')

      get "/#{competition.year}/#{competition.slug}/simple_access_login/new"
      expect(response).to match_html_fixture.with_affix('login-new')

      post "/#{competition.year}/#{competition.slug}/simple_access_login/",
           params: { simple_access_login: { name: 'test', password: 'secret' } }
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
      expect(session["simple_access_#{competition.id}"]).to eq access.id

      get "/#{competition.year}/#{competition.slug}"
      expect(response).to match_html_fixture.with_affix('with-logout-link')

      delete "/#{competition.year}/#{competition.slug}/simple_access_login/"
      expect(session.key?("simple_access_#{competition.id}")).to be false
    end
  end
end
