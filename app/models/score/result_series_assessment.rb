# frozen_string_literal: true

# == Schema Information
#
# Table name: score_result_series_assessments
#
#  id            :uuid             not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  assessment_id :bigint           not null
#  result_id     :uuid             not null
#
# Indexes
#
#  index_score_result_series_assessments_on_assessment_id  (assessment_id)
#  index_score_result_series_assessments_on_result_id      (result_id)
#
# Foreign Keys
#
#  fk_rails_...  (result_id => score_results.id)
#
class Score::ResultSeriesAssessment < ApplicationRecord
  belongs_to :assessment, class_name: 'Series::Assessment', inverse_of: :assessment_score_results
  belongs_to :result, class_name: 'Score::Result', inverse_of: :result_series_assessments

  def self.exists_for?(competition)
    competition.score_results.joins(:result_series_assessments).exists?
  end

  schema_validations
end
