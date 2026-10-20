# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/score/list_factories' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let!(:hl) { create(:discipline, :hl, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:assessment_hl_female) { create(:assessment, competition:, discipline: hl, band: female) }

  describe 'type' do
    it 'rejects unknown types in every step' do
      sign_in user

      get competition_nested('score/list_factories/new')
      post competition_nested('score/list_factories'),
           params: { score_list_factory: { discipline_id: hl.id, next_step: 'assessments' } }
      expect(response).to redirect_to(competition_nested('score/list_factories/edit'))

      %w[Competition Score::ListFactories::Unknown].each do |type|
        patch competition_nested('score/list_factories'),
              params: { score_list_factory: { next_step: 'names', type:, assessment_ids: [assessment_hl_female.id] } }
        expect(response).to have_http_status(:unprocessable_content)

        get competition_nested('score/list_factories/edit')
        expect(response).to have_http_status(:success)
      end
      expect(Score::ListFactory.pluck(:type)).to eq ['Score::ListFactory']
    end
  end

  describe 'copy list' do
    let!(:list_without_results) do
      create(:score_list, competition:, assessments: [assessment_hl_female], results: [])
    end

    it 'redirects with error message when factory is invalid' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/score/list_factories/copy_list/#{list_without_results.id}"
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/score/lists"
      expect(flash[:notice]).to eq 'Gültigkeitsprüfung ist fehlgeschlagen: Ergebnislisten muss ausgefüllt werden'
      expect(Score::ListFactory.count).to eq 0
    end
  end
end
