# frozen_string_literal: true

# == Schema Information
#
# Table name: series_person_points_corrections
#
#  id                     :uuid             not null, primary key
#  points_correction      :integer
#  points_correction_hint :string
#  round_key              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  competition_id         :uuid
#  person_id              :bigint
#
# Indexes
#
#  index_series_person_points_corrections_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Series::PersonPointsCorrection < ApplicationRecord
  belongs_to :competition, class_name: 'Competition'
  belongs_to :person, class_name: 'FireSportStatistics::Person'

  schema_validations

  def round_key_config
    @round_key_config ||= Series::AssessmentConfig.find_by_round_key(round_key, :person)
  end

  def possible_assessment_configs
    @possible_assessment_configs ||= competition.score_results.pluck(:series_person_round_keys).flatten.compact.uniq
                                                .map do |round_key|
                                                  Series::AssessmentConfig.find_by_round_key(round_key, :person)
                                                end
  end

  def possible_round_keys
    possible_assessment_configs.map do |config|
      [config.round_full_name, config.round_key]
    end
  end

  def possible_people
    competition.people.map(&:fire_sport_statistics_person_with_dummy).uniq.sort
  end
end
