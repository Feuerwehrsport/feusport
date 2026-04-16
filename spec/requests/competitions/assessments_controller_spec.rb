# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assessment do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let!(:la) { create(:discipline, :la, competition:) }
  let!(:gs) { create(:discipline, :gs, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:male) { create(:band, :male, competition:) }

  describe 'assessments managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/assessments"
      expect(response).to match_html_fixture.with_affix('index-empty')

      # create an other assessment
      create(:assessment, discipline: gs, band: male, competition:)

      # GET new
      get "/#{competition.year}/#{competition.slug}/assessments/new"
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with name_preview
      expect do
        post "/#{competition.year}/#{competition.slug}/assessments",
             params: { name_preview: 1, assessment: { discipline_id: la.id, band_id: female.id } }
        expect(response).to have_http_status(:success)
        expect(response.body).to eq '{"name":"Löschangriff Nass - Frauen"}'
      end.not_to change(described_class, :count)

      # POST create with failure
      post "/#{competition.year}/#{competition.slug}/assessments", params: { assessment: { forced_name: 'Foo' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      # POST create an own assessment
      post "/#{competition.year}/#{competition.slug}/assessments", params: { assessment: {
        discipline_id: la.id, band_id: female.id
      } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/assessments")
      follow_redirect!

      # GET index
      expect(response).to match_html_fixture.with_affix('index-two-entries')

      assessment = described_class.find_by(discipline: la)
      expect(assessment.band).to eq female
      expect(assessment.name).to eq 'Löschangriff Nass - Frauen'

      # GET index XLSX
      get "/#{competition.year}/#{competition.slug}/assessments.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        "attachment; filename=\"wertungen.xlsx\"; filename*=UTF-8''wertungen.xlsx",
      )
      expect(response).to have_http_status(:success)

      # GET index PDF
      get "/#{competition.year}/#{competition.slug}/assessments.pdf"
      expect(response).to match_pdf_fixture.with_affix('index-as-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        "inline; filename=\"wertungen.pdf\"; filename*=UTF-8''wertungen.pdf",
      )
      expect(response).to have_http_status(:success)

      # GET show
      get "/#{competition.year}/#{competition.slug}/assessments/#{assessment.id}"
      expect(response).to match_html_fixture.with_affix('show')

      # GET edit
      get "/#{competition.year}/#{competition.slug}/assessments/#{assessment.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      # PATCH update with failure
      patch "/#{competition.year}/#{competition.slug}/assessments/#{assessment.id}",
            params: { assessment: { discipline_id: 'not-exists' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      # PATCH update
      patch "/#{competition.year}/#{competition.slug}/assessments/#{assessment.id}",
            params: { assessment: { forced_name: 'other' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/assessments")

      assessment = described_class.find_by(discipline: la)
      expect(assessment.name).to eq 'other'

      # PATCH update with name_preview
      expect do
        patch "/#{competition.year}/#{competition.slug}/assessments/#{assessment.id}",
              params: { name_preview: 1, assessment: { discipline_id: la.id } }
        expect(response).to have_http_status(:success)
        expect(response.body).to eq '{"name":"Löschangriff Nass - Frauen"}'
      end.not_to change(described_class, :count)

      expect do
        # DELETE destroy
        delete "/#{competition.year}/#{competition.slug}/assessments/#{assessment.id}"
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/assessments")
      end.to change(described_class, :count).by(-1)
    end
  end

  describe 'generate_score_result' do
    it 'generates result on create' do
      sign_in user

      expect do
        post "/#{competition.year}/#{competition.slug}/assessments", params: { assessment: {
          discipline_id: la.id, band_id: female.id, generate_score_result: false
        } }
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/assessments")
      end.not_to change(Score::Result, :count)

      expect do
        post "/#{competition.year}/#{competition.slug}/assessments", params: { assessment: {
          discipline_id: la.id, band_id: female.id, generate_score_result: true
        } }
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/assessments")
      end.to change(Score::Result, :count).by(1)
    end
  end

  context 'when no login performed' do
    let!(:assessment) { create(:assessment, competition:, discipline: la, band: female) }

    it 'fails' do
      get competition_nested('assessments/new')
      expect_access_denied

      post competition_nested('assessments'), params: { assessment: { forced_name: 'Foo' } }
      expect_access_denied

      get competition_nested("assessments/#{assessment.id}/edit")
      expect_access_denied

      patch competition_nested("assessments/#{assessment.id}"), params: { assessment: { forced_name: 'Foo' } }
      expect_access_denied

      delete competition_nested("assessments/#{assessment.id}")
      expect_access_denied
    end
  end
end
