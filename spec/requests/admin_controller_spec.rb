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
end
