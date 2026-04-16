# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamListRestriction do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:band) { create(:band, competition:) }
  let!(:discipline) { create(:discipline, :la, competition:) }
  let!(:team1) { create(:team, competition:, band:) }
  let!(:team2) { create(:team, competition:, band:) }

  describe 'team_list_restrictions managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/team_list_restrictions"
      expect(response).to match_html_fixture.with_affix('index-empty')

      get "/#{competition.year}/#{competition.slug}/team_list_restrictions/new"
      expect(response).to match_html_fixture.with_affix('new-not-selected')

      get "/#{competition.year}/#{competition.slug}/team_list_restrictions/new?team1_id=#{team1.id}"
      expect(response).to match_html_fixture.with_affix('new-selected')

      post "/#{competition.year}/#{competition.slug}/team_list_restrictions",
           params: { team_list_restriction: { discipline_id: '' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/team_list_restrictions",
             params: { team_list_restriction: { discipline_id: discipline.id, team1_id: team1.id, team2_id: team2.id,
                                                restriction: 'same_run' } }
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/team_list_restrictions")
        follow_redirect!
      end.to change(described_class, :count).by(1)

      # GET index
      expect(response).to match_html_fixture.with_affix('index-one-entry')

      restriction = described_class.last

      # GET edit
      get "/#{competition.year}/#{competition.slug}/team_list_restrictions/#{restriction.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      # PUT update with failure
      put "/#{competition.year}/#{competition.slug}/team_list_restrictions/#{restriction.id}",
          params: { team_list_restriction: { restriction: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      # PUT update
      put "/#{competition.year}/#{competition.slug}/team_list_restrictions/#{restriction.id}",
          params: { team_list_restriction: { restriction: 'before' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/team_list_restrictions")

      expect(restriction.reload.restriction).to eq 'before'

      expect do
        # DELETE destroy
        delete "/#{competition.year}/#{competition.slug}/team_list_restrictions/#{restriction.id}"
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/team_list_restrictions")
      end.to change(described_class, :count).by(-1)
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested('team_list_restrictions')
      expect_access_denied

      get competition_nested('team_list_restrictions/new')
      expect_access_denied

      post competition_nested('team_list_restrictions'),
           params: { team_list_restriction: { discipline_id: '' } }
      expect_access_denied
    end
  end
end
