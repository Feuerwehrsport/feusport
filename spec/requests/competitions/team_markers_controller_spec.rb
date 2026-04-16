# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamMarker do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  describe 'team_markers managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/team_markers"
      expect(response).to match_html_fixture.with_affix('index-empty')

      # GET new
      get "/#{competition.year}/#{competition.slug}/team_markers/new"
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with failure
      post "/#{competition.year}/#{competition.slug}/team_markers", params: { team_marker: { value_type: 'boolean' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      # POST create an own discipline
      post "/#{competition.year}/#{competition.slug}/team_markers",
           params: { team_marker: { name: 'Angereist?', value_type: 'boolean' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/team_markers")
      follow_redirect!

      # GET index
      expect(response).to match_html_fixture.with_affix('index-one-entries')

      team_marker = described_class.last

      # GET edit
      get "/#{competition.year}/#{competition.slug}/team_markers/#{team_marker.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      # PUT update with failure
      put "/#{competition.year}/#{competition.slug}/team_markers/#{team_marker.id}",
          params: { team_marker: { name: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      # PUT update
      put "/#{competition.year}/#{competition.slug}/team_markers/#{team_marker.id}",
          params: { team_marker: { name: 'Other' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/team_markers")

      expect(team_marker.reload.name).to eq 'Other'

      expect do
        # DELETE destroy
        delete "/#{competition.year}/#{competition.slug}/team_markers/#{team_marker.id}"
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/team_markers")
      end.to change(described_class, :count).by(-1)
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested('team_markers')
      expect_access_denied

      get competition_nested('team_markers/new')
      expect_access_denied

      post competition_nested('team_markers'), params: { team_marker: { value_type: 'boolean' } }
      expect_access_denied
    end
  end
end
