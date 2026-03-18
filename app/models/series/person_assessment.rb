# frozen_string_literal: true

# == Schema Information
#
# Table name: series_person_assessments
#
#  id         :integer          not null, primary key
#  discipline :string(3)        not null
#  key        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  round_id   :integer          not null
#
# Indexes
#
#  index_series_person_assessments_on_discipline  (discipline)
#  index_series_person_assessments_on_key         (key)
#  index_series_person_assessments_on_round_id    (round_id)
#
class Series::PersonAssessment < ApplicationRecord
  belongs_to :round, class_name: 'Series::Round'
  has_many :cups, through: :round, class_name: 'Series::Cup'
  has_many :person_participations, class_name: 'Series::PersonParticipation', dependent: :destroy

  scope :round, ->(round_id) { where(round_id:) }
  scope :year, ->(year) { joins(:round).where(series_rounds: { year: }) }
  scope :round_name, ->(round_name) { joins(:round).where(series_rounds: { name: round_name }) }

  schema_validations

  delegate :rows, :name, to: :config

  def config
    round.person_assessments_configs.find { |c| c.key == key }
  end
end
