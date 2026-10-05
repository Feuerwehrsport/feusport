# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  describe 'host check' do
    it 'redirects requests with wrong host to configured host' do
      host! 'feusport.example.org'
      get '/info?foo=bar'
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to('http://www.example.com/info?foo=bar')
    end

    it 'does not redirect requests with configured host' do
      get '/info'
      expect(response).to have_http_status(:success)
    end
  end
end
