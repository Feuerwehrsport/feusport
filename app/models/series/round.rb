# frozen_string_literal: true

# == Schema Information
#
# Table name: series_rounds
#
#  id                              :integer          not null, primary key
#  full_cup_count                  :integer          default(4), not null
#  name                            :string(100)      not null
#  person_assessments_config_jsonb :jsonb
#  team_assessments_config_jsonb   :jsonb
#  year                            :integer          not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  kind_id                         :bigint
#
# Indexes
#
#  index_series_rounds_on_kind_id  (kind_id)
#

class Series::Round < ApplicationRecord
  has_many :series_round_competition_associations, dependent: :destroy, class_name: 'Series::RoundCompetitionAssociation'
  has_many :competitions, class_name: 'Competition', through: :series_round_competition_associations
  has_many :cups, class_name: 'Series::Cup', dependent: :destroy, inverse_of: :round
  has_many :team_assessments, class_name: 'Series::TeamAssessment', dependent: :destroy
  has_many :team_participations, through: :team_assessments, class_name: 'Series::TeamParticipation'
  has_many :person_assessments, class_name: 'Series::PersonAssessment', dependent: :destroy
  has_many :person_participations, through: :person_assessments, class_name: 'Series::PersonParticipation',
                                   source: :person_participations

  schema_validations

  default_scope -> { order(year: :desc, name: :asc) }
  scope :exists_for, ->(competition) do
    where(
      Series::RoundCompetitionAssociation
      .where(Series::RoundCompetitionAssociation.arel_table[:round_id].eq(arel_table[:id]))
      .where(competition: competition).arel.exists,
    )
  end

  %i[team person].each do |entity_key|
    jsonb_as_text :"#{entity_key}_assessments_config_jsonb"
    validate do
      send("#{entity_key}_assessments_configs").each_with_index do |config, index|
        next if config.valid?

        config.errors.each do |error|
          errors.add(:"#{entity_key}_assessments_config_jsonb_text", "Eintrag #{index}: #{error.full_message}")
          errors.add(:"#{entity_key}_assessments_config_jsonb", "Eintrag #{index}: #{error.full_message}")
        end
      end
    end

    define_method("#{entity_key}_assessments_configs") do
      unless send("#{entity_key}_assessments_config_jsonb").is_a?(Array)
        errors.add(:"#{entity_key}_assessments_config_jsonb", :invalid)
        errors.add(:"#{entity_key}_assessments_config_jsonb_text", :invalid)
        return []
      end
      send("#{entity_key}_assessments_config_jsonb").map do |h|
        unless h.is_a?(Hash)
          errors.add(:"#{entity_key}_assessments_config_jsonb", :invalid)
          errors.add(:"#{entity_key}_assessments_config_jsonb_text", :invalid)
          return []
        end
        Series::AssessmentConfig.new(h).tap do |config|
          config.round = self
          config.entity_key = entity_key
        end
      end
    end
  end

  def self.possible_series_round_keys(entity_key, with_round_keys: [], discipline_key: nil, year: Date.current.year)
    out = []
    unscoped.find_each do |round|
      round.public_send(:"#{entity_key}_assessments_configs").map do |config|
        if (with_round_keys.present? && config.round_key.in?(with_round_keys)) ||
           ((discipline_key.blank? || discipline_key.in?(config.disciplines)) && round.year >= year)
          out.push([config.round_full_name, config.round_key])
        end
      end
    end
    out.sort_by(&:first)
  end

  def disciplines
    (team_assessments_configs + person_assessments_configs).map(&:disciplines).flatten.uniq.sort
  end

  def round
    self
  end

  def team_config_for(key)
    team_assessments_configs.find { |c| c.key == key }
  end

  def person_config_for(key)
    person_assessments_configs.find { |c| c.key == key }
  end

  def showable_cups(today)
    @showable_cups ||= begin
      me = Series::Cup.find_or_create_today!(self, today)
      me_online = cups.find { |cup| cup.dummy_for_competition.nil? && cup.competition_date == today.date }
      sorted = cups.sort_by(&:competition_date)
      sorted.reject { |cup| cup.competition_date > today.date }
            .reject { |cup| cup.competition_date < today.date && cup.dummy_for_competition.present? }
            .reject { |cup| me_online && cup == me }
    end
  end

  def team_count
    team_participations.pluck(:team_id, :team_number).uniq.count
  end

  def person_count
    person_participations.pluck(:person_id).uniq.count
  end

  def cups_left
    full_cup_count - cup_count
  end

  def cup_count
    attributes['cup_count'] || cups.count
  end

  def complete?
    cups_left&.zero? || false
  end
end
