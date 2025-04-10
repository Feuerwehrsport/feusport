# frozen_string_literal: true

# == Schema Information
#
# Table name: score_result_references
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  multi_result_id :uuid             not null
#  result_id       :uuid             not null
#
# Indexes
#
#  index_score_result_references_on_multi_result_id  (multi_result_id)
#  index_score_result_references_on_result_id        (result_id)
#
# Foreign Keys
#
#  fk_rails_...  (multi_result_id => score_results.id)
#  fk_rails_...  (result_id => score_results.id)
#
class Score::ResultReference < ApplicationRecord
  belongs_to :result, class_name: 'Score::Result'
  belongs_to :multi_result, class_name: 'Score::Result'

  schema_validations
end
