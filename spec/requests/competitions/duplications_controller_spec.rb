# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/documents' do
  let!(:competition) { create(:competition) }
  let!(:old) { create(:competition, name: 'D-Cup') }

  let(:band) { create(:band, :female, competition: old) }
  let(:multi_result_method) { :sum_of_best }

  let(:hl) { create(:discipline, :hl, competition: old) }
  let(:hb) { create(:discipline, :hb, competition: old) }
  let!(:assessment_hl) { create(:assessment, competition: old, discipline: hl, band:) }
  let!(:assessment_hb) { create(:assessment, competition: old, discipline: hb, band:) }
  let!(:result_zk) do
    Score::Result.create!(competition: old, forced_name: 'Zweikampf - Frauen', multi_result_method:,
                          image_key: :zk, results: [result_hb, result_hl])
  end
  let!(:result_hl) { create(:score_result, competition: old, assessment: assessment_hl) }
  let!(:result_hb) { create(:score_result, competition: old, assessment: assessment_hb) }
  let!(:competition_result) { create(:score_competition_result, competition: old, results: [result_hb, result_hl]) }

  let!(:user) { competition.users.first }

  describe 'duplicate competition' do
    it 'uses create method' do
      sign_in user

      get competition_nested('presets')
      expect(response).to match_html_fixture.with_affix('presets')

      get competition_nested('duplication/new?duplication[duplicate_from_id]=not-found')
      expect(response).to redirect_to competition_nested('presets')

      get competition_nested("duplication/new?duplication[duplicate_from_id]=#{old.id}")
      expect(response).to match_html_fixture.with_affix('new')

      post competition_nested('duplication'),
           params: { duplication: { confirm: '0', duplicate_from_id: old.id } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        expect do
          expect do
            expect do
              expect do
                expect do
                  expect do
                    expect do
                      post competition_nested('duplication'),
                           params: { duplication: { confirm: '1', duplicate_from_id: old.id } }
                      expect(response).to redirect_to(competition_nested)
                    end.not_to change(Competition, :count)
                  end.to change(Band, :count).by(1)
                end.to change(Discipline, :count).by(2)
              end.to change(Assessment, :count).by(2)
            end.to change(Score::Result, :count).by(3)
          end.to change(Score::ResultReference, :count).by(2)
        end.to change(Score::CompetitionResult, :count).by(1)
      end.to change(Score::CompetitionResultReference, :count).by(2)

      expect(competition.reload.preset_ran).to be(true)
    end
  end
end
