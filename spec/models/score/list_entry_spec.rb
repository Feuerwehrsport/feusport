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
end
