# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::Score::ListConditionsController do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let!(:la) { create(:discipline, :la, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:male) { create(:band, :male, competition:) }
  let!(:assessment_male) { create(:assessment, competition:, discipline: la, band: male) }
  let!(:assessment_female) { create(:assessment, competition:, discipline: la, band: female) }
  let(:result_la) { create(:score_result, competition:, assessment: assessment_female) }

  describe 'list factory creation' do
    it 'shows warning on not useful conditions' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/score/list_factories/new"

      post competition_nested('score/list_factories'),
           params: { score_list_factory: { discipline_id: la.id,
                                           next_step: 'assessments' } }
      follow_redirect!

      factory = Score::ListFactory.last
      factory.update!(next_step: :names, assessments: [assessment_male, assessment_female])
      factory.update!(next_step: :tracks, name: factory.default_name, shortcut: factory.default_shortcut)
      factory.update!(next_step: :results, track_count: 2)
      factory.update!(next_step: :generator, results: [result_la])
      factory.update!(type: 'Score::ListFactories::Simple')
      factory = factory.reload
      factory.update!(next_step: :finish)

      get competition_nested('score/list_factories/edit')
      expect(response).to match_html_fixture.with_affix('edit-empty')

      get competition_nested("score/list_conditions/new?list_factory_id=#{factory.id}")
      expect(response).to match_html_fixture.with_affix('new')

      post competition_nested('score/list_conditions'),
           params: { score_list_condition: {
             list_id: '',
             factory_id: factory.id,
             track: '',
             assessment_ids: ['', assessment_male.id],
           } }
      expect(response).to match_html_fixture.with_affix('new-with-warning').for_status(422)

      post competition_nested('score/list_conditions'),
           params: { score_list_condition: {
             list_id: '',
             factory_id: factory.id,
             track: '1',
             assessment_ids: ['', assessment_male.id],
           } }

      follow_redirect!
      expect(response).to match_html_fixture.with_affix('edit-with-warning')

      post competition_nested('score/list_conditions'),
           params: { score_list_condition: {
             list_id: '',
             factory_id: factory.id,
             track: '2',
             assessment_ids: ['', assessment_female.id],
           } }

      follow_redirect!
      expect(response).to match_html_fixture.with_affix('edit-without-warning')

      condition = Score::ListCondition.find_by(track: 2)

      get competition_nested("score/list_conditions/#{condition.id}/edit")
      expect(response).to match_html_fixture.with_affix('condition-edit')

      patch competition_nested("score/list_conditions/#{condition.id}"),
            params: { score_list_condition: {
              list_id: '',
              factory_id: factory.id,
              track: '',
              assessment_ids: ['', assessment_male.id],
            } }
      expect(response).to match_html_fixture.with_affix('condition-edit-with-warning').for_status(422)

      patch competition_nested("score/list_conditions/#{condition.id}"),
            params: { score_list_condition: {
              list_id: '',
              factory_id: factory.id,
              track: '1',
              assessment_ids: ['', assessment_male.id],
            } }
      follow_redirect!

      expect do
        delete competition_nested("score/list_conditions/#{condition.id}")
      end.to change(Score::ListCondition, :count).by(-1)
    end
  end
end
