# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::SimpleAccessLoginsController do
  let!(:competition) { create(:competition, visible: true) }

  before { SimpleAccess.create!(competition:, name: 'test', password: 'secret') }

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
           params: { simple_access_login: { name: 'unknown', password: 'secret' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(session.key?("simple_access_#{competition.id}")).to be false
    end
  end
end
