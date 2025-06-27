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
  pending "add some examples to (or delete) #{__FILE__}"
end
