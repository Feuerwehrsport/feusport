# frozen_string_literal: true

# == Schema Information
#
# Table name: score_competition_result_references
#
#  id                    :uuid             not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  competition_result_id :uuid             not null
#  result_id             :uuid             not null
#
# Indexes
#
#  index_score_competition_result_references_on_competition_result  (competition_result_id)
#  index_score_competition_result_references_on_result_id           (result_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_result_id => score_competition_results.id)
#  fk_rails_...  (result_id => score_results.id)
#
class Score::CompetitionResultReference < ApplicationRecord
  belongs_to :result, class_name: 'Score::Result', touch: true
  belongs_to :competition_result, class_name: 'Score::CompetitionResult'

  schema_validations
end
