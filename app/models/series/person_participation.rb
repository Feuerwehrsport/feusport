# frozen_string_literal: true

# == Schema Information
#
# Table name: series_person_participations
#
#  id                   :integer          not null, primary key
#  points               :integer          default(0), not null
#  rank                 :integer          not null
#  time                 :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  cup_id               :integer          not null
#  person_assessment_id :integer          not null
#  person_id            :integer          not null
#
# Indexes
#
#  index_series_person_participations_on_cup_id                (cup_id)
#  index_series_person_participations_on_person_assessment_id  (person_assessment_id)
#  index_series_person_participations_on_person_id             (person_id)
#
class Series::PersonParticipation < ApplicationRecord
  include Firesport::TimeInvalid

  belongs_to :person, class_name: 'FireSportStatistics::Person', inverse_of: :series_person_participations
  belongs_to :cup, class_name: 'Series::Cup', inverse_of: :person_participations
  belongs_to :person_assessment, class_name: 'Series::PersonAssessment'

  schema_validations

  def entity
    person
  end

  def entity_id
    person_id
  end

  def result_entry
    @result_entry = Score::ResultEntry.new(time_with_valid_calculation: time)
  end

  def result_entry_with_points
    "#{result_entry.human_time} (#{points})"
  end
end
