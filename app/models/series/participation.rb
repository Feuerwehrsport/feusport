# frozen_string_literal: true

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
