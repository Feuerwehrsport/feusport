# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_conditions
#
#  id             :uuid             not null, primary key
#  track          :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  factory_id     :uuid
#  list_id        :uuid
#
# Indexes
#
#  index_score_list_conditions_on_competition_id  (competition_id)
#  index_score_list_conditions_on_factory_id      (factory_id)
#  index_score_list_conditions_on_list_id         (list_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (factory_id => score_list_factories.id)
#  fk_rails_...  (list_id => score_lists.id)
#
require 'rails_helper'

RSpec.describe Score::ListCondition do
  describe '.useful?' do
    it 'return true on empty conditions' do
      list = instance_double(Score::List, conditions: [], track_count: 2)
      expect(described_class.useful?(list)).to be(true)
    end

    it 'return true on useful conditions' do
      list = instance_double(Score::List, conditions: [
                               instance_double(described_class, track: 1, assessment_ids: %w[a b]),
                               instance_double(described_class, track: 2, assessment_ids: %w[c]),
                             ], track_count: 2, assessment_ids: %w[a b c])
      expect(described_class.useful?(list)).to be(true)
    end

    it 'return false on not useful conditions' do
      # only track 1
      list = instance_double(Score::List, conditions: [
                               instance_double(described_class, track: 1, assessment_ids: %w[a b]),
                               instance_double(described_class, track: 1, assessment_ids: %w[c]),
                             ], track_count: 2, assessment_ids: %w[a b c])
      expect(described_class.useful?(list)).to be(false)

      # only track 1
      list = instance_double(Score::List, conditions: [
                               instance_double(described_class, track: 1, assessment_ids: %w[a b c]),
                             ], track_count: 2, assessment_ids: %w[a b c])
      expect(described_class.useful?(list)).to be(false)

      # not all assessments
      list = instance_double(Score::List, conditions: [
                               instance_double(described_class, track: 1, assessment_ids: %w[a]),
                               instance_double(described_class, track: 2, assessment_ids: %w[c]),
                             ], track_count: 2, assessment_ids: %w[a b c])
      expect(described_class.useful?(list)).to be(false)
    end
  end

  describe 'Score::ListCondition::Check' do
    let(:competition) { create(:competition) }
    let(:la) { create(:discipline, :la, competition:) }
    let(:female) { create(:band, :female, competition:) }
    let(:male) { create(:band, :male, competition:) }
    let(:assessment_male) { create(:assessment, competition:, discipline: la, band: male) }
    let(:assessment_female) { create(:assessment, competition:, discipline: la, band: female) }

    let(:cond1) { described_class.new(track: 1, assessments: [assessment_male]) }
    let(:cond2) { described_class.new(track: 2, assessments: [assessment_female]) }
    let(:list) {       Score::List.new(conditions: [cond1, cond2], track_count: 2) }

    let(:entry_1_male) { instance_double(Score::ListEntry, track: 1, assessment: assessment_male) }
    let(:entry_1_female) { instance_double(Score::ListEntry, track: 1, assessment: assessment_female) }

    describe 'valid?' do
      it 'adds errors for each invalid line' do
        check = Score::ListCondition::Check.new(list)
        expect(check.valid?([entry_1_male])).to be true
        expect(check.errors).to eq []

        check = Score::ListCondition::Check.new(list)
        expect(check.valid?([entry_1_female])).to be false
        expect(check.errors).to eq [[entry_1_female, cond1]]
      end
    end
  end
end
