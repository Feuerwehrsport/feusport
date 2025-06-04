# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/unlockings' do
  let!(:competition) { create(:competition, locked_at: Time.current) }
  let!(:user) { competition.users.first }

  describe 'destroy competition' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/unlocking/new"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/unlocking",
           params: { competitions_unlocking: { confirm: '0' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/unlocking",
             params: { competitions_unlocking: { confirm: '1' } }
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}")
      end.not_to change(Competition, :count)

      expect(competition.reload.locked_at).to be_nil
    end
  end
end
