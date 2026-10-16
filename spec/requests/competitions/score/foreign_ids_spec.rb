# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Foreign ids in score associations' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let(:discipline) { create(:discipline, :la, competition:) }
  let(:band) { create(:band, :female, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }

  let(:other_user) { create(:user, email: 'fremd@example.com') }
  let(:other_competition) { create(:competition, name: 'Fremd-Cup', users: [other_user]) }
  let(:other_discipline) { create(:discipline, :la, competition: other_competition) }
  let(:other_band) { create(:band, :female, competition: other_competition) }
  let(:other_assessment) do
    create(:assessment, competition: other_competition, discipline: other_discipline, band: other_band)
  end
  let(:other_result) { create(:score_result, competition: other_competition, assessment: other_assessment) }

  before { sign_in user }

  it 'ignores foreign ids for lists' do
    list = create(:score_list, competition:, assessments: [assessment], results: [result])

    patch competition_nested("score/lists/#{list.id}"),
          params: { score_list: { assessment_ids: ['', assessment.id, other_assessment.id],
                                  result_ids: ['', result.id, other_result.id] } }

    expect(list.reload.assessments).to eq [assessment]
    expect(list.results).to eq [result]
    expect(Score::ListAssessment.where(assessment: other_assessment)).to be_empty
    expect(Score::ResultList.where(result: other_result)).to be_empty
  end

  it 'ignores foreign ids for competition results' do
    competition_result = create(:score_competition_result, competition:)

    patch competition_nested("score/competition_results/#{competition_result.id}"),
          params: { score_competition_result: { result_ids: ['', result.id, other_result.id] } }

    expect(competition_result.reload.results).to eq [result]
    expect(Score::CompetitionResultReference.where(result: other_result)).to be_empty
  end

  it 'ignores foreign ids for multi results' do
    multi_result = Score::Result.create!(competition:, forced_name: 'Zweikampf', image_key: 'la',
                                         multi_result_method: :sum_of_best, results: [result])

    patch competition_nested("score/results/#{multi_result.id}"),
          params: { score_result: { result_ids: ['', result.id, other_result.id] } }

    expect(multi_result.reload.results).to eq [result]
    expect(Score::ResultReference.where(result: other_result)).to be_empty
  end

  it 'ignores foreign ids for list factories' do
    get competition_nested('score/list_factories/new')
    post competition_nested('score/list_factories'),
         params: { score_list_factory: { discipline_id: discipline.id, next_step: 'assessments' } }
    factory = Score::ListFactory.last

    patch competition_nested('score/list_factories'),
          params: { score_list_factory: { next_step: 'names',
                                          assessment_ids: ['', assessment.id, other_assessment.id] } }
    expect(factory.reload.assessments).to eq [assessment]
    expect(Score::ListFactoryAssessment.where(assessment: other_assessment)).to be_empty

    factory.update!(next_step: :tracks, name: factory.default_name, shortcut: factory.default_shortcut)
    factory.update!(next_step: :results, track_count: 2)

    patch competition_nested('score/list_factories'),
          params: { score_list_factory: { next_step: 'generator', result_ids: ['', result.id, other_result.id] } }
    expect(factory.reload.results).to eq [result]
    expect(Score::ResultListFactory.where(result: other_result)).to be_empty
  end

  it 'ignores foreign ids for list conditions' do
    list = create(:score_list, competition:, assessments: [assessment], results: [result], track_count: 2)
    condition = Score::ListCondition.create!(competition:, list:, track: 1, assessments: [assessment])

    patch competition_nested("score/list_conditions/#{condition.id}"),
          params: { score_list_condition: { assessment_ids: ['', assessment.id, other_assessment.id] } }

    expect(condition.reload.assessments).to eq [assessment]
    expect(Score::ListConditionAssessment.where(assessment: other_assessment)).to be_empty
  end
end
