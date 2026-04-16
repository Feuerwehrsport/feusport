# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competition/team_imports' do
  let!(:competition) { create(:competition) }
  let!(:user) { competition.users.first }
  let!(:band) { create(:band, competition:) }

  describe 'team import process' do
    it 'uses import rows' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/team_import/new"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/team_import",
           params: { team_import: { band_id: band.id } }
      expect(response).to match_html_fixture.with_affix('new-with-errors').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/team_import",
             params: { team_import: { band_id: band.id, import_rows: "Rostock\nFF Bargeshagen" } }
        expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/teams"
      end.to change(Team, :count).by(2)

      team1 = Team.find_by!(name: 'Rostock')
      expect(team1.shortcut).to eq 'Rostock'
      team2 = Team.find_by!(name: 'FF Bargeshagen')
      expect(team2.shortcut).to eq 'Bargeshagen'
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested('team_import/new')
      expect_access_denied

      post competition_nested('team_import'),
           params: { team_import: { band_id: band.id } }
      expect_access_denied
    end
  end
end
