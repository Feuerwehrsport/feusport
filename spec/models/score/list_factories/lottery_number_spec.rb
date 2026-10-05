# frozen_string_literal: true

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
