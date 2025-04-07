# frozen_string_literal: true

# == Schema Information
#
# Table name: series_cups
#
#  id                       :bigint           not null, primary key
#  competition_date         :date             not null
#  competition_place        :string(100)      not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  dummy_for_competition_id :uuid
#  round_id                 :integer          not null
#
class Series::Cup < ApplicationRecord
  belongs_to :round, class_name: 'Series::Round', inverse_of: :cups
  belongs_to :dummy_for_competition, class_name: 'Competition'
  has_many :assessments, through: :round, class_name: 'Series::Assessment'
  has_many :participations, dependent: :destroy, class_name: 'Series::Participation', inverse_of: :cup

  default_scope -> { order(:competition_date) }

  schema_validations

  def self.find_or_create_today!(round, competition)
    round.cups.find_or_create_by!(round:, competition_date: Date.new(2200), competition_place: '-',
                                  dummy_for_competition: competition)
  end

  def competition_place
    dummy_for_competition&.place || super
  end

  def competition_date
    dummy_for_competition&.date || super
  end
end
