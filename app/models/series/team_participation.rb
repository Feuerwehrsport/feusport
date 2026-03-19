# frozen_string_literal: true

# == Schema Information
#
# Table name: series_team_participations
#
#  id                     :integer          not null, primary key
#  points                 :integer          default(0), not null
#  points_correction      :integer
#  points_correction_hint :string(200)
#  rank                   :integer          not null
#  team_gender            :integer          not null
#  team_number            :integer          not null
#  time                   :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  cup_id                 :integer          not null
#  team_assessment_id     :integer          not null
#  team_id                :integer          not null
#
# Indexes
#
#  index_series_team_participations_on_cup_id              (cup_id)
#  index_series_team_participations_on_team_assessment_id  (team_assessment_id)
#  index_series_team_participations_on_team_id             (team_id)
#  index_series_team_participations_on_team_number         (team_number)
#

class Series::TeamParticipation < ApplicationRecord
  include Firesport::TimeInvalid

  belongs_to :cup, class_name: 'Series::Cup', inverse_of: :team_participations
  belongs_to :team_assessment, class_name: 'Series::TeamAssessment'
  belongs_to :team, class_name: 'FireSportStatistics::Team'

  schema_validations

  def entity_id
    "#{team_id}-#{team_number}"
  end

  def result_entry
    @result_entry = Score::ResultEntry.new(time_with_valid_calculation: time)
  end

  def result_entry_with_points
    "#{result_entry.human_time} (#{points_with_correction_string})"
  end

  def points_with_correction
    points + (points_correction || 0)
  end

  def points_with_correction_string
    if points_correction.nil?
      points
    else
      "#{points}#{'+' unless points_correction < 0}#{points_correction}"
    end
  end
end
