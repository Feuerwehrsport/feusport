# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_condition_assessments
#
#  id            :uuid             not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  assessment_id :uuid             not null
#  condition_id  :uuid             not null
#
# Indexes
#
#  index_score_list_condition_assessments_on_assessment_id  (assessment_id)
#  index_score_list_condition_assessments_on_condition_id   (condition_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (condition_id => score_list_conditions.id)
#
require 'rails_helper'

RSpec.describe Score::ListConditionAssessment do
  pending "add some examples to (or delete) #{__FILE__}"
end
