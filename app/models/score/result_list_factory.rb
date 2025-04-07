# frozen_string_literal: true

# == Schema Information
#
# Table name: score_result_list_factories
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  list_factory_id :uuid             not null
#  result_id       :uuid             not null
#
# Indexes
#
#  index_score_result_list_factories_on_list_factory_id  (list_factory_id)
#  index_score_result_list_factories_on_result_id        (result_id)
#
# Foreign Keys
#
#  fk_rails_...  (list_factory_id => score_list_factories.id)
#  fk_rails_...  (result_id => score_results.id)
#
class Score::ResultListFactory < ApplicationRecord
  belongs_to :list_factory, class_name: 'Score::ListFactory'
  belongs_to :result, class_name: 'Score::Result'

  schema_validations
end
