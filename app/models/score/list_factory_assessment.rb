# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_factory_assessments
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  assessment_id   :uuid             not null
#  list_factory_id :uuid             not null
#
# Indexes
#
#  index_score_list_factory_assessments_on_assessment_id    (assessment_id)
#  index_score_list_factory_assessments_on_list_factory_id  (list_factory_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (list_factory_id => score_list_factories.id)
#
class Score::ListFactoryAssessment < ApplicationRecord
  belongs_to :assessment
  belongs_to :list_factory, class_name: 'Score::ListFactory'

  schema_validations
end
