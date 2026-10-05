# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_factories
#
#  id                       :uuid             not null, primary key
#  best_count               :integer
#  hidden                   :boolean          default(FALSE), not null
#  name                     :string(100)
#  separate_target_times    :boolean
#  shortcut                 :string(50)
#  show_best_of_run         :boolean          default(FALSE), not null
#  single_competitors_first :boolean          default(TRUE), not null
#  status                   :string(50)
#  track                    :integer
#  track_count              :integer
#  type                     :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  before_list_id           :uuid
#  before_result_id         :uuid
#  competition_id           :uuid             not null
#  discipline_id            :uuid             not null
#  session_id               :string(200)      not null
#
# Indexes
#
#  index_score_list_factories_on_before_list_id    (before_list_id)
#  index_score_list_factories_on_before_result_id  (before_result_id)
#  index_score_list_factories_on_competition_id    (competition_id)
#  index_score_list_factories_on_discipline_id     (discipline_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Score::ListFactories::LotteryNumber do
  let(:competition) { create(:competition, lottery_numbers: true) }
  let(:band) { create(:band, :female, competition:) }

  let(:discipline) { create(:discipline, :la, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }

  let(:factory) do
    described_class.new(
      competition:, session_id: '1',
      discipline:, assessments: [assessment], name: 'long name',
      shortcut: 'short', track_count: 2, results: [result]
    )
  end

  describe '.generator_possible?' do
    it 'is only possible for group disciplines with lottery numbers' do
      expect(described_class.generator_possible?(discipline)).to be true
      expect(described_class.generator_possible?(create(:discipline, :hl, competition:))).to be false
      expect(described_class.generator_possible?(create(:discipline, :fs, competition:))).to be false
    end
  end

  describe '#perform' do
    let(:team1) { create(:team, competition:, band:, lottery_number: 3) }
    let(:team2) { create(:team, competition:, band:, lottery_number: 1) }
    let(:team3) { create(:team, competition:, band:, lottery_number: 2) }

    before do
      [team1, team2, team3].each { |team| create_assessment_request(team, assessment, 0) }
    end

    it 'creates entries ordered by lottery number' do
      new_list = factory.list
      expect { factory.perform }.to change(Score::ListEntry, :count).by(3)

      expect(new_list.entries.reload.map { |e| [e.entity, e.run, e.track] }).to eq [
        [team2, 1, 1], [team3, 1, 2], [team1, 2, 1]
      ]
    end
  end
end
