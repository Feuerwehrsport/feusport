# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/series/rounds' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let!(:la) { create(:discipline, :la, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:assessment_female) { create(:assessment, competition:, discipline: la, band: female) }

  let!(:team_female1) { create(:team, band: female, competition:) }
  let!(:team_female2) { create(:team, band: female, competition:) }

  let(:result_la) { create(:score_result, competition:, assessment: assessment_female) }

  let!(:series_team_assessment) { create(:series_team_assessment) }
  let!(:series_person_assessment) { create(:series_person_assessment, id: 42) }
  let(:round) { series_person_assessment.round }

  let!(:hl) { create(:discipline, :hl, competition:) }
  let!(:assessment_hl_female) { create(:assessment, competition:, discipline: hl, band: female) }

  let(:result_hl) { create(:score_result, competition:, assessment: assessment_hl_female) }
  let(:person1) { create(:person, :generated, competition:) }
  let(:person2) { create(:person, :generated, competition:) }

  describe 'display round calculation' do
    before do
      view_sanitizer.gsub(%r{/series/rounds/\d+.pdf}, 'PDF_URL')
      view_sanitizer.gsub(%r{/series/assessments/\d+.pdf}, 'PDF_URL')
    end

    it 'displays' do
      sign_in user

      create_score_list(result_la, team_female1 => 1200, team_female2 => 1300)
      result_la.update(series_assessments: [series_team_assessment])

      create_score_list(result_hl, person1 => 800, person2 => 900)
      result_hl.update(series_assessments: [series_person_assessment])

      get "/#{competition.year}/#{competition.slug}/series/rounds"
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/series/rounds/#{round.id}"

      get "/#{competition.year}/#{competition.slug}/series/rounds/#{round.id}"
      expect(response).to match_html_fixture.with_affix('show-round')

      get "/#{competition.year}/#{competition.slug}/series/rounds/#{round.id}.pdf"
      expect(response).to match_pdf_fixture.with_affix('show-round-as-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        "inline; filename=\"d-cup.pdf\"; filename*=UTF-8''d-cup.pdf",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/series/assessments/#{series_person_assessment.id}"
      expect(response).to match_html_fixture.with_affix('show-assessment')

      get "/#{competition.year}/#{competition.slug}/series/assessments/#{series_person_assessment.id}.pdf"
      expect(response).to match_pdf_fixture.with_affix('show-assessment-as-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        "inline; filename=\"hakenleitersteigen-mannlich.pdf\"; filename*=UTF-8''hakenleitersteigen-mannlich.pdf",
      )
      expect(response).to have_http_status(:success)
    end
  end
end
