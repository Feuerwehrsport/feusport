# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamMarkerBlockValue do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:band) { create(:band, competition:) }
  let!(:team) { create(:team, competition:, band:) }
  let!(:boolean) { create(:team_marker, competition:) }
  let!(:date) { create(:team_marker, :date, competition:) }
  let!(:string) { create(:team_marker, :string, competition:) }

  describe 'team_marker_values managements' do
    it 'uses CRUD' do
      sign_in user

      get competition_nested('teams')
      expect(response).to match_html_fixture.with_affix('teams')

      get competition_nested("team_marker_block_values/edit?band_id=#{band.id}")
      expect(response).to match_html_fixture.with_affix('edit')

      # PUT update
      put competition_nested('team_marker_block_values'),
          params: { band_id: band.id, team_marker_block_value: {
            team_marker_values_attributes: {
              '0' => { team_id: team.id, team_marker_id: boolean.id, boolean_value: '1' },
              '1' => { team_id: team.id, team_marker_id: date.id, date_value: 'foobar' },
              '2' => { team_id: team.id, team_marker_id: string.id, string_value: 'test values' },
            },
          } }
      expect(response).to redirect_to(competition_nested('teams'))

      expect(TeamMarkerValue.find_by(team_marker: boolean).boolean_value).to be true
      expect(TeamMarkerValue.find_by(team_marker: date).date_value).to be_nil
      expect(TeamMarkerValue.find_by(team_marker: string).string_value).to eq 'test values'

      get competition_nested("team_marker_block_values/edit?band_id=#{band.id}")
      expect(response).to match_html_fixture.with_affix('edit2')

      # PUT update
      put competition_nested('team_marker_block_values'),
          params: { band_id: band.id, team_marker_block_value: {
            team_marker_values_attributes: {
              '0' => { team_id: team.id, team_marker_id: boolean.id, boolean_value: '1' },
              '1' => { team_id: team.id, team_marker_id: date.id, date_value: '2025-06-15' },
              '2' => { team_id: team.id, team_marker_id: string.id, string_value: 'test values' },
            },
          } }
      expect(response).to redirect_to(competition_nested('teams'))

      expect(TeamMarkerValue.find_by(team_marker: boolean).boolean_value).to be true
      expect(TeamMarkerValue.find_by(team_marker: date).date_value).to eq Date.parse('2025-06-15')
      expect(TeamMarkerValue.find_by(team_marker: string).string_value).to eq 'test values'

      get competition_nested('teams')
      expect(response).to match_html_fixture.with_affix('teams2')
    end
  end

  context 'when a value is invalid' do
    it 'renders edit again with errors and saves nothing' do
      sign_in user

      put competition_nested('team_marker_block_values'),
          params: { band_id: band.id, team_marker_block_value: {
            team_marker_values_attributes: {
              '0' => { team_id: team.id, team_marker_id: string.id, string_value: 'test values' },
              '1' => { team_id: team.id, team_marker_id: boolean.id, boolean_value: '' },
            },
          } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to eq :check_errors
      expect(response.body).to include('<div class="invalid-feedback">Ja/Nein muss ausgefüllt werden</div>')
      expect(TeamMarkerValue.count).to eq 0
    end
  end

  context 'when ids belong to other bands or competitions' do
    let(:other_band) { create(:band, :male, competition:) }
    let(:other_band_team) { create(:team, competition:, band: other_band, name: 'Andere Gruppe') }
    let(:other_user) { create(:user, :other) }
    let(:other_competition) { create(:competition, name: 'Fremd-Cup', users: [other_user]) }
    let(:foreign_band) { create(:band, competition: other_competition) }
    let(:foreign_team) { create(:team, competition: other_competition, band: foreign_band) }
    let(:foreign_marker) { create(:team_marker, :string, competition: other_competition) }

    it 'ignores them' do
      sign_in user

      put competition_nested('team_marker_block_values'),
          params: { band_id: band.id, team_marker_block_value: {
            team_marker_values_attributes: {
              '0' => { team_id: foreign_team.id, team_marker_id: foreign_marker.id, string_value: 'fremd' },
              '1' => { team_id: team.id, team_marker_id: foreign_marker.id, string_value: 'fremd' },
              '2' => { team_id: other_band_team.id, team_marker_id: string.id, string_value: 'andere Gruppe' },
              '3' => { team_id: team.id, team_marker_id: string.id, string_value: 'eigen' },
            },
          } }
      expect(response).to redirect_to(competition_nested('teams'))

      expect(TeamMarkerValue.pluck(:team_id, :team_marker_id, :string_value)).to eq [[team.id, string.id, 'eigen']]
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested("team_marker_block_values/edit?band_id=#{band.id}")
      expect_access_denied

      put competition_nested('team_marker_block_values'),
          params: { band_id: band.id, team_marker_block_value: {} }
      expect_access_denied
    end
  end
end
