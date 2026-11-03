# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminController do
  let(:user) { create(:user) }

  describe 'GET /admin-jobs' do
    context 'when no login performed' do
      it 'redirects to login' do
        get '/admin-jobs/'
        expect_access_denied
        expect(session[:requested_url_before_login]).to eq '/admin-jobs/'
      end
    end

    context 'when user is not admin' do
      it 'denies access' do
        sign_in user
        get '/admin-jobs/'
        expect(response).to redirect_to('/')
        expect(flash[:alert]).to eq 'Zugriff verweigert'
      end
    end
  end

  describe 'admin dashboard' do
    it 'denies access for other users' do
      get '/admin'
      expect_access_denied

      sign_in user
      get '/admin'
      expect(response).to redirect_to('/')
      expect(response.body).not_to include('href="/admin"')
    end

    context 'when user is admin' do
      let(:competition) { create(:competition) }

      before do
        user.update!(admin: true)
        sign_in user
      end

      it 'shows the dashboard' do
        get '/admin'
        expect(response).to match_html_fixture
        expect(response.body).to include('href="/admin"', 'Keine offenen Übertragungen', 'noch nie')

        FireSportStatistics::Publishing.create!(competition:, user:)
        create(:fire_sport_statistics_person)
        SolidQueue::Job.create!(class_name: 'ImportSuggestionsJob', queue_name: 'default')

        get '/admin'
        expect(response.body).to include('MV-Cup', 'Erneut versuchen', 'bereits eingeplant', '29.02.2024')
        expect(response.body).not_to include('Import starten')

        SolidQueue::Job.last.failed_with(StandardError.new('kaputt'))
        get '/admin'
        expect(response.body).to include('Import starten', '<b>1</b>')
      end

      it 'triggers actions' do
        expect { post '/admin/import' }.to have_enqueued_job(ImportSuggestionsJob)
        expect(response).to redirect_to('/admin')
        expect(flash[:notice]).to eq :import_started

        expect(Rails.cache).to receive(:clear)
        delete '/admin/cache'
        expect(response).to redirect_to('/admin')
        expect(flash[:notice]).to eq :cache_cleared

        expect { post '/admin/publishings' }.to have_enqueued_job(FireSportStatistics::Publishing::Worker)
        expect(response).to redirect_to('/admin')
        expect(flash[:notice]).to eq :publishings_retried
      end
    end
  end
end
