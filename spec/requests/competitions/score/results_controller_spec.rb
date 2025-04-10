# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/score/results' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let!(:hl) { create(:discipline, :hl, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:assessment_hl_female) { create(:assessment, competition:, discipline: hl, band: female) }

  let(:team) { create(:team, band: female, competition:) }
  let(:person1) { create(:person, :generated, band: female, competition:, team:) }
  let(:person2) { create(:person, :generated, band: female, competition:, team:) }
  let(:person3) { create(:person, :generated, band: female, competition:, team:) }

  describe 'results managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/score/results"
      expect(response).to match_html_fixture.with_affix('index-empty')

      get "/#{competition.year}/#{competition.slug}/score/results/new"
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with name_preview
      expect do
        post "/#{competition.year}/#{competition.slug}/score/results",
             params: { name_preview: 1, score_result: { assessment_id: assessment_hl_female.id } }
        expect(response).to have_http_status(:success)
        expect(response.body).to eq '{"name":"Hakenleitersteigen - Frauen"}'
      end.not_to change(Score::Result, :count)

      post "/#{competition.year}/#{competition.slug}/score/results",
           params: { score_result: { forced_name: '', assessment_id: nil } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/score/results",
             params: { score_result: { forced_name: '', assessment_id: assessment_hl_female.id,
                                       group_assessment: true, group_score_count: 2 } }
      end.to change(Score::Result, :count).by(1)

      follow_redirect!
      expect(response).to match_html_fixture.with_affix('show')

      result = Score::Result.first

      create_score_list(result, person1 => 1200, person2 => 1300, person3 => 1400)

      get "/#{competition.year}/#{competition.slug}/score/results/#{result.id}"
      expect(response).to match_html_fixture.with_affix('show-with-results')

      get "/#{competition.year}/#{competition.slug}/score/results/#{result.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/score/results/#{result.id}",
            params: { score_result: { assessment_id: nil } }
      expect(response).to match_html_fixture.with_affix('edit-with-error').for_status(422)

      patch "/#{competition.year}/#{competition.slug}/score/results/#{result.id}",
            params: { score_result: { forced_name: 'Cooler Name' } }
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/score/results/#{result.id}"
      follow_redirect!

      # PATCH update with name_preview
      expect do
        patch "/#{competition.year}/#{competition.slug}/score/results/#{result.id}",
              params: { name_preview: 1, score_result: { assessment_id: assessment_hl_female.id } }
        expect(response).to have_http_status(:success)
        expect(response.body).to eq '{"name":"Hakenleitersteigen - Frauen"}'
      end.not_to change(Score::Result, :count)

      result = Score::Result.find(result.id)

      expect(result.reload.name).to eq 'Cooler Name'

      get "/#{competition.year}/#{competition.slug}/score/results/#{result.id}.pdf"
      expect(response).to match_pdf_fixture.with_affix('full-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="cooler-name.pdf"; ' \
        "filename*=UTF-8''cooler-name.pdf",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/score/results/#{result.id}.pdf?only=single_competitors"
      expect(response).to match_pdf_fixture.with_affix('single_competitors-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="cooler-name.pdf"; ' \
        "filename*=UTF-8''cooler-name.pdf",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/score/results/#{result.id}.pdf?only=group_assessment"
      expect(response).to match_pdf_fixture.with_affix('group_assessment-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="cooler-name.pdf"; ' \
        "filename*=UTF-8''cooler-name.pdf",
      )
      expect(response).to have_http_status(:success)

      # GET index XLSX
      get "/#{competition.year}/#{competition.slug}/score/results/#{result.id}.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        'attachment; filename="cooler-name.xlsx"; ' \
        "filename*=UTF-8''cooler-name.xlsx",
      )
      expect(response).to have_http_status(:success)

      expect do
        delete "/#{competition.year}/#{competition.slug}/score/results/#{result.id}"
      end.to change(Score::Result, :count).by(-1)
    end
  end

  describe 'change assessment' do
    let!(:result) { create(:score_result, competition:, assessment: assessment_hl_female) }

    let!(:male) { create(:band, :male, competition:) }
    let!(:assessment_hl_male) { create(:assessment, competition:, discipline: hl, band: male) }

    let!(:la) { create(:discipline, :la, competition:) }
    let!(:assessment_la_female) { create(:assessment, competition:, discipline: la, band: female) }

    it 'blocks bad changes' do
      sign_in user

      patch "/#{competition.year}/#{competition.slug}/score/results/#{result.id}",
            params: { score_result: { assessment_id: assessment_la_female.id } }
      expect(response).to match_html_fixture.with_affix('edit-with-error').for_status(422)

      patch "/#{competition.year}/#{competition.slug}/score/results/#{result.id}",
            params: { score_result: { assessment_id: assessment_hl_male.id } }
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/score/results/#{result.id}"

      expect(result.reload.assessment_id).to eq assessment_hl_male.id
    end
  end

  describe 'zweikampf' do
    let!(:hb) { create(:discipline, :hb, competition:) }
    let!(:assessment_hb_female) { create(:assessment, competition:, discipline: hb, band: female) }
    let!(:result_hb) { create(:score_result, competition:, assessment: assessment_hb_female) }
    let!(:result_hl) { create(:score_result, competition:, assessment: assessment_hl_female) }

    it 'allows to create zweikampf results' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/score/results/new?multi_result=true"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/score/results",
           params: { multi_result: 'true', score_result: { image_key: 'zk' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/score/results",
             params: { multi_result: 'true', score_result: {
               image_key: 'zk', result_ids: [result_hb.id], forced_name: 'Zweikampf',
               multi_result_method: 'sum_of_best'
             } }
      end.to change(Score::Result, :count).by(1)

      result = Score::Result.where.not(id: [result_hl.id, result_hb.id]).last
      expect(result.calculation_method).to eq 'default'
      expect(result.multi_result_method).to eq 'sum_of_best'

      get "/#{competition.year}/#{competition.slug}/score/results/#{result.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/score/results/#{result.id}",
            params: { score_result: { result_ids: [result_hl.id, result_hb.id] } }
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/score/results/#{result.id}"

      expect(result.reload.results).to contain_exactly(result_hl, result_hb)
    end
  end
end
