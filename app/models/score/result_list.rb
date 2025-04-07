# frozen_string_literal: true

# == Schema Information
#
# Table name: score_result_lists
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  list_id    :uuid             not null
#  result_id  :uuid             not null
#
# Indexes
#
#  index_score_result_lists_on_list_id    (list_id)
#  index_score_result_lists_on_result_id  (result_id)
#
# Foreign Keys
#
#  fk_rails_...  (list_id => score_lists.id)
#  fk_rails_...  (result_id => score_results.id)
#
class Score::ResultList < ApplicationRecord
  belongs_to :list, touch: true
  belongs_to :result
  schema_validations
end
