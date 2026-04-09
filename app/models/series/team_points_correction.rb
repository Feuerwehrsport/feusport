# frozen_string_literal: true

# == Schema Information
#
# Table name: series_team_points_corrections
#
#  id                     :uuid             not null, primary key
#  discipline             :string           not null
#  points_correction      :integer          not null
#  points_correction_hint :string           not null
#  round_key              :string           not null
#  team_number            :integer          default(1), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  competition_id         :uuid             not null
#  team_id                :bigint           not null
#
# Indexes
#
#  index_series_team_points_corrections_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Series::TeamPointsCorrection < ApplicationRecord
  belongs_to :competition, class_name: 'Competition'
  belongs_to :team, class_name: 'FireSportStatistics::Team'

  schema_validations

  def round_key_config
    @round_key_config ||= Series::AssessmentConfig.find_by_round_key(round_key, :team)
  end

  def possible_assessment_configs
    @possible_assessment_configs ||= competition.score_results.pluck(:series_team_round_keys).flatten.compact.uniq
                                                .map do |round_key|
                                                  Series::AssessmentConfig.find_by_round_key(round_key, :team)
                                                end
  end

  def possible_round_keys
    possible_assessment_configs.map do |config|
      [config.round_full_name, config.round_key]
    end
  end

  def possible_disciplines
    possible_assessment_configs.map(&:disciplines).flatten.uniq.map do |d|
      [d.upcase, d]
    end
  end

  def possible_teams
    competition.teams.map(&:fire_sport_statistics_team_with_dummy).uniq.sort
  end

  def to_export_hash
    {
      discipline:,
      points_correction:,
      points_correction_hint:,
      round_key:,
      team_number:,
      team_id:,
    }
  end
end
