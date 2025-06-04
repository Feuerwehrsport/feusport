# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/team_deletions' do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }
  let!(:team) { create(:team, competition:, band:) }
  let!(:user) { competition.users.first }

  let(:la) { create(:discipline, :la, competition:) }
  let(:assessment_la) { create(:assessment, competition:, discipline: la, band:) }
  let(:result_la) { create(:score_result, competition:, assessment: assessment_la) }
  let(:list_la) { create_score_list(result_la, team => 2413) }

  describe 'destroy team' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/teams/#{team.id}/deletion/new"
      expect(response).to match_html_fixture.with_affix('new')

      list_la # create

      get "/#{competition.year}/#{competition.slug}/teams/#{team.id}/deletion/new"
      expect(response).to match_html_fixture.with_affix('new-with-warning')

      post "/#{competition.year}/#{competition.slug}/teams/#{team.id}/deletion",
           params: { team_deletion: { confirm: '0' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/teams/#{team.id}/deletion",
             params: { team_deletion: { confirm: '1' } }
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/teams")
      end.to change(Team, :count).by(-1)
    end
  end
end
