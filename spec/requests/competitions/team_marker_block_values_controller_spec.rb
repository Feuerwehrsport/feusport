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
end
