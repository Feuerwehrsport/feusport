# frozen_string_literal: true

# == Schema Information
#
# Table name: series_participations
#
#  id            :bigint           not null, primary key
#  points        :integer          default(0), not null
#  rank          :integer          not null
#  team_number   :integer
#  time          :integer          not null
#  type          :string(100)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  assessment_id :integer          not null
#  cup_id        :integer          not null
#  person_id     :integer
#  team_id       :integer
#
class Series::Participation < ApplicationRecord
  include Firesport::TimeInvalid

  belongs_to :cup, class_name: 'Series::Cup', inverse_of: :participations
  belongs_to :assessment, class_name: 'Series::Assessment', inverse_of: :participations

  validates :cup, :assessment, :time, :points, :rank, presence: true
  schema_validations

  def result_entry
    @result_entry = Score::ResultEntry.new(time_with_valid_calculation: time)
  end

  def result_entry_with_points
    "#{result_entry.human_time} (#{points})"
  end
end
