# frozen_string_literal: true

# == Schema Information
#
# Table name: series_team_participations
#
#  id                 :integer          not null, primary key
#  points             :integer          default(0), not null
#  rank               :integer          not null
#  team_gender        :integer          not null
#  team_number        :integer          not null
#  time               :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  cup_id             :integer          not null
#  team_assessment_id :integer          not null
#  team_id            :integer          not null
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
    "#{result_entry.human_time} (#{points})"
  end
end
