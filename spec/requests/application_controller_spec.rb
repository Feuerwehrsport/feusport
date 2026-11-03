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

    it 'ignores url_for options from params' do
      host! 'feusport.example.org'
      get '/info?domain=evil.com&script_name=@evil.com&host=evil.com&subdomain=evil'
      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to eq(
        'http://www.example.com/info?domain=evil.com&script_name=@evil.com&host=evil.com&subdomain=evil',
      )
    end

    it 'redirects requests with wrong port to configured port' do
      host! 'www.example.com:8080'
      get '/info?foo=bar'
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to('http://www.example.com/info?foo=bar')
    end

    it 'does not redirect requests with configured host' do
      get '/info'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'content security policy' do
    it 'forbids inline scripts and plugins' do
      get '/info'
      policy = response.headers['Content-Security-Policy'].split(';').map(&:strip)

      expect(policy).to include("default-src 'self'", "object-src 'none'", "base-uri 'self'", "form-action 'self'",
                                "frame-ancestors 'self'")
      expect(response.headers['X-Frame-Options']).to eq 'SAMEORIGIN'
      expect(policy.find { |directive| directive.start_with?('script-src') }).not_to include('unsafe')
    end

    it 'provides a script nonce for the inline importmap of mission control' do
      get '/info'
      policy = response.headers['Content-Security-Policy'].split(';').map(&:strip)
      nonce = policy.find { |directive| directive.start_with?('script-src') }[/'nonce-([^']+)'/, 1]

      expect(nonce).to be_present
      expect(response.body).to include(%(<meta name="csp-nonce" content="#{nonce}" />))
      expect(policy.find { |directive| directive.start_with?('style-src') }).not_to include('nonce')
    end
  end
end
