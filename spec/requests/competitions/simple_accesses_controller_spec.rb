# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::SimpleAccessesController do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  describe 'accesses managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/accesses"
      expect(response).to match_html_fixture.with_affix('index-empty')

      # GET new
      get "/#{competition.year}/#{competition.slug}/simple_accesses/new"
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with failure
      post "/#{competition.year}/#{competition.slug}/simple_accesses",
           params: { simple_access: { name: 'foo', password: 'secret', password_confirmation: 'wrong' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      # POST create an access_request
      expect do
        post "/#{competition.year}/#{competition.slug}/simple_accesses",
             params: { simple_access: { name: 'foo', password: 'secret', password_confirmation: 'secret' } }
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")
        follow_redirect!
      end.to change(SimpleAccess, :count).by(1)

      # GET index
      expect(response).to match_html_fixture.with_affix('index-one-entries')

      access = SimpleAccess.first

      expect do
        # DELETE destroy
        delete "/#{competition.year}/#{competition.slug}/simple_accesses/#{access.id}"
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")
        expect(flash[:notice]).to eq :deleted
      end.to change(SimpleAccess, :count).by(-1)
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested('simple_accesses/new')
      expect_access_denied

      post competition_nested('simple_accesses'),
           params: { simple_access: { name: 'foo' } }
      expect_access_denied
    end
  end
end
