# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/score/competition_results' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let!(:la) { create(:discipline, :la, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:assessment_female) { create(:assessment, competition:, discipline: la, band: female) }

  let!(:team_female1) { create(:team, band: female, competition:) }
  let!(:team_female2) { create(:team, band: female, competition:) }

  let(:result_la) { create(:score_result, competition:, assessment: assessment_female) }

  describe 'results managements' do
    it 'uses CRUD' do
      sign_in user

      create_score_list(result_la, team_female1 => 1200, team_female2 => 1300)

      get "/#{competition.year}/#{competition.slug}/score/competition_results"
      expect(response).to match_html_fixture.with_affix('index-empty')

      get "/#{competition.year}/#{competition.slug}/score/competition_results/new"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/score/competition_results",
           params: { score_competition_result: { name: '' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/score/competition_results",
             params: { score_competition_result: { name: 'Frauen', hidden: '1', result_type: 'places_to_points',
                                                   result_ids: ['', result_la.id] } }
      end.to change(Score::CompetitionResult, :count).by(1)

      follow_redirect!
      expect(response).to match_html_fixture.with_affix('index-with-hidden')

      result = Score::CompetitionResult.first

      get "/#{competition.year}/#{competition.slug}/score/competition_results/#{result.id}"
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/score/competition_results"

      get "/#{competition.year}/#{competition.slug}/score/competition_results/#{result.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/score/competition_results/#{result.id}",
            params: { score_competition_result: { name: '' } }
      expect(response).to match_html_fixture.with_affix('edit-with-error').for_status(422)

      Score::CompetitionResult.create!(competition:, name: 'other', result_type: 'places_to_points')

      patch "/#{competition.year}/#{competition.slug}/score/competition_results/#{result.id}",
            params: { score_competition_result: { hidden: '0' } }
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/score/competition_results"
      follow_redirect!

      expect(response).to match_html_fixture.with_affix('index')

      get "/#{competition.year}/#{competition.slug}/score/competition_results.pdf"
      expect(response).to match_pdf_fixture.with_affix('all-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="gesamtwertung.pdf"; ' \
        "filename*=UTF-8''gesamtwertung.pdf",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/score/competition_results/#{result.id}.pdf"
      expect(response).to match_pdf_fixture.with_affix('one-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="gesamtwertung-frauen.pdf"; ' \
        "filename*=UTF-8''gesamtwertung-frauen.pdf",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/score/competition_results.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        'attachment; filename="gesamtwertung.xlsx"; ' \
        "filename*=UTF-8''gesamtwertung.xlsx",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/score/competition_results/#{result.id}.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        'attachment; filename="gesamtwertung-frauen.xlsx"; ' \
        "filename*=UTF-8''gesamtwertung-frauen.xlsx",
      )
      expect(response).to have_http_status(:success)

      expect do
        delete "/#{competition.year}/#{competition.slug}/score/competition_results/#{result.id}"
      end.to change(Score::CompetitionResult, :count).by(-1)
    end
  end

  context 'when no login performed' do
    let!(:score_competition_result) { create(:score_competition_result, competition:) }

    it 'fails' do
      get competition_nested('score/competition_results/new')
      expect_access_denied

      post competition_nested('score/competition_results'),
           params: { score_competition_result: { name: 'Foo' } }
      expect_access_denied

      get competition_nested("score/competition_results/#{score_competition_result.id}/edit")
      expect_access_denied

      patch competition_nested("score/competition_results/#{score_competition_result.id}"),
            params: { score_competition_result: { name: 'Foo' } }
      expect_access_denied

      delete competition_nested("score/competition_results/#{score_competition_result.id}")
      expect_access_denied
    end
  end
end
