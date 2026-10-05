# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_entries
#
#  id                :uuid             not null, primary key
#  assessment_type   :integer          default("group_competitor"), not null
#  entity_type       :string(50)       not null
#  result_type       :string(20)       default("waiting"), not null
#  run               :integer          not null
#  time              :integer
#  time_left_target  :integer
#  time_right_target :integer
#  track             :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  assessment_id     :uuid             not null
#  competition_id    :uuid             not null
#  entity_id         :uuid             not null
#  list_id           :uuid             not null
#
# Indexes
#
#  index_score_list_entries_on_assessment_id   (assessment_id)
#  index_score_list_entries_on_competition_id  (competition_id)
#  index_score_list_entries_on_list_id         (list_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (list_id => score_lists.id)
#
require 'rails_helper'

RSpec.describe Score::ListEntry do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:) }
  let(:assessment) { create(:assessment, competition:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:score_list) { create(:score_list, competition:, assessments: [assessment], results: [result]) }
  let(:score_list_entry) { build(:score_list_entry, list: score_list, assessment:, competition:) }

  describe 'validation' do
    context 'when track count' do
      it 'validates track count from list' do
        expect(score_list_entry).to be_valid
        score_list_entry.track = 5
        expect(score_list_entry).not_to be_valid
        expect(score_list_entry.errors.attribute_names).to include :track
      end
    end

    context 'when edit_second_time_before given' do
      let(:score_list_entry) do
        create(:score_list_entry, list: score_list, assessment:, competition:, edit_second_time: '22.88')
      end

      it 'checks it is the same' do
        expect(score_list_entry.edit_second_time_before).to eq '22.88'
        score_list_entry.edit_second_time = '22.89'

        score_list_entry.edit_second_time_before = '11.33'
        expect(score_list_entry).not_to be_valid
        expect(score_list_entry.errors).to include :changed_while_editing

        score_list_entry.edit_second_time_before = '22.88'
        expect(score_list_entry).to be_valid

        score_list_entry.edit_second_time_before = nil
        expect(score_list_entry).to be_valid
      end
    end
  end

  describe '.insert_random_values' do
    let(:person1) { create(:person, :generated, competition:, band:) }
    let(:person2) { create(:person, :generated, competition:, band:) }
    let!(:waiting_entry) do
      create(:score_list_entry, list: score_list, assessment:, competition:, entity: person1, track: 1)
    end
    let!(:valid_entry) do
      create(:score_list_entry, :result_valid, list: score_list, assessment:, competition:, entity: person2,
                                               track: 2, time: 1234)
    end

    it 'fills only waiting entries with valid times' do
      described_class.insert_random_values

      expect(waiting_entry.reload).to be_result_valid
      expect(waiting_entry.time).to be_between(1900, 2300)
      expect(valid_entry.reload.time).to eq 1234
    end

    context 'when list has separate target times' do
      let(:score_list) do
        create(:score_list, competition:, assessments: [assessment], results: [result], separate_target_times: true)
      end

      it 'fills target times too' do
        described_class.insert_random_values

        waiting_entry.reload
        expect(waiting_entry).to be_result_valid
        expect(waiting_entry.time_left_target).to be_between(1900, 2300)
        expect(waiting_entry.time_right_target).to be_between(1900, 2300)
        expect(waiting_entry.time).to eq [waiting_entry.time_left_target, waiting_entry.time_right_target].max
      end
    end
  end
end
