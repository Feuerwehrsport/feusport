# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamMarker do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:band) { create(:band, competition:) }
  let(:team) { create(:team, competition:, band:) }
  let(:team_marker) { create(:team_marker, competition:) }

  describe 'team_marker_values managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/teams/#{team.id}/markers/#{team_marker.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      # PUT update with failure
      put "/#{competition.year}/#{competition.slug}/teams/#{team.id}/markers/#{team_marker.id}",
          params: { team_marker_value: { boolean_value: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      # PUT update
      put "/#{competition.year}/#{competition.slug}/teams/#{team.id}/markers/#{team_marker.id}",
          params: { team_marker_value: { boolean_value: 'true' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/teams")

      expect(TeamMarkerValue.first.boolean_value).to be true

      # PUT update
      put "/#{competition.year}/#{competition.slug}/teams/#{team.id}/markers/#{team_marker.id}?return_to=team",
          params: { team_marker_value: { boolean_value: 'false' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/teams/#{team.id}")

      expect(TeamMarkerValue.first.boolean_value).to be false
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested("teams/#{team.id}/markers/#{team_marker.id}/edit")
      expect_access_denied

      put competition_nested("teams/#{team.id}/markers/#{team_marker.id}"),
          params: { team_marker_value: { boolean_value: '' } }
      expect_access_denied
    end
  end
end
