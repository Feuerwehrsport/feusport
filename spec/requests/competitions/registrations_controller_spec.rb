# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/registrations' do
  let!(:competition) { create(:competition) }
  let!(:user) { competition.users.first }

  describe 'edit competition registrations' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/registration/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/registration",
            params: { competition: { registration_open: 'open', registration_open_until: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      patch "/#{competition.year}/#{competition.slug}/registration",
            params: { competition: { registration_open: 'open', registration_open_until: '2024-02-28' } }
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"

      expect(competition.reload.registration_open).to eq 'open'
    end

    context 'when no login performed' do
      it 'fails' do
        get competition_nested('registration/edit')
        expect_access_denied

        patch competition_nested('registration'),
              params: { competition: { registration_open: 'open', registration_open_until: '' } }
        expect_access_denied
      end
    end
  end
end
