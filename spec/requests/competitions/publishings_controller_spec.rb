# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/publishings' do
  let!(:competition) { create(:competition) }
  let!(:user) { competition.users.first }

  describe 'publishing competition' do
    it 'uses CRUD' do
      expect(FireSportStatistics::Publishing::Worker).to receive(:perform_later)

      sign_in user

      get "/#{competition.year}/#{competition.slug}/publishing/new"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/publishing",
           params: { competitions_publishing: { confirm: '0' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/publishing",
             params: { competitions_publishing: { confirm: '1' } }
        expect(response).to redirect_to(competition_show_path)
      end.to change(FireSportStatistics::Publishing, :count).by(1)
    end

    context 'when no login performed' do
      it 'fails' do
        get competition_nested('publishing/new')
        expect_access_denied

        post competition_nested('publishing'),
             params: { competitions_publishing: { confirm: '0' } }
        expect_access_denied
      end
    end
  end
end
