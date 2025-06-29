# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_conditions
#
#  id             :uuid             not null, primary key
#  track          :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  factory_id     :uuid
#  list_id        :uuid
#
# Indexes
#
#  index_score_list_conditions_on_competition_id  (competition_id)
#  index_score_list_conditions_on_factory_id      (factory_id)
#  index_score_list_conditions_on_list_id         (list_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (factory_id => score_list_factories.id)
#  fk_rails_...  (list_id => score_lists.id)
#

class Score::ListCondition < ApplicationRecord
  belongs_to :competition
  belongs_to :list, class_name: 'Score::List'
  belongs_to :factory, class_name: 'Score::ListFactory'
  has_many :list_condition_assessments, class_name: 'Score::ListConditionAssessment', dependent: :destroy,
                                        foreign_key: :condition_id, inverse_of: :condition
  has_many :assessments, class_name: 'Assessment', through: :list_condition_assessments

  schema_validations
  validates :track, numericality: { only_integer: true, graeter_than: 0, less_than_or_equal_to: :track_count }
  validates :list, presence: true, if: -> { factory.blank? }
  validates :list, :factory, same_competition: true

  def self.useful?(list_or_factory)
    conditions = list_or_factory.conditions.to_a
    return true if conditions.empty?
    return false if conditions.count != list_or_factory.track_count
    return false if conditions.map(&:track).uniq.count != conditions.count
    return false if (list_or_factory.assessment_ids - conditions.map(&:assessment_ids).flatten.uniq).present?

    true
  end

  def track_count
    (factory || list)&.track_count || 100
  end

  def list_entry_valid?(entry)
    return true if entry.track != track
    return true if entry.assessment.in?(assessments)

    false
  end

  class Check
    attr_reader :conditions, :errors

    def initialize(list)
      @errors = []
      @conditions = list.conditions.to_a
    end

    def valid?(entries)
      @errors = []
      conditions.each do |condition|
        entries.each do |entry|
          @errors.push([entry, condition]) unless condition.list_entry_valid?(entry)
        end
      end
      @errors.empty?
    end
  end
end
