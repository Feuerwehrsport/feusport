# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_assessments
#
#  id            :uuid             not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  assessment_id :uuid             not null
#  list_id       :uuid             not null
#
# Indexes
#
#  index_score_list_assessments_on_assessment_id  (assessment_id)
#  index_score_list_assessments_on_list_id        (list_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (list_id => score_lists.id)
#
class Score::ListAssessment < ApplicationRecord
  belongs_to :assessment, touch: true
  belongs_to :list

  schema_validations
end
