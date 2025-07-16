# frozen_string_literal: true

# == Schema Information
#
# Table name: series_rounds
#
#  id             :bigint           not null, primary key
#  aggregate_type :string(100)      not null
#  full_cup_count :integer          default(4), not null
#  name           :string(100)      not null
#  year           :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Series::Round < ApplicationRecord
  include Series::Importable

  has_many :cups, class_name: 'Series::Cup', dependent: :destroy, inverse_of: :round
  has_many :assessments, class_name: 'Series::Assessment', dependent: :destroy, inverse_of: :round
  has_many :participations, through: :assessments, class_name: 'Series::Participation'

  schema_validations

  default_scope -> { order(year: :desc, name: :asc) }
  scope :exists_for, ->(competition) do
    where(id: competition.score_results.joins(result_series_assessments: { assessment: :round })
      .select(Series::Round.arel_table[:id]))
  end

  class GenderWrapper
    def self.find(merged_id)
      id, gender = merged_id.to_s.split('-')
      return nil unless gender&.to_sym.in?(Genderable::KEYS)

      round = Series::Round.find_by(id:)
      new(round, gender.to_sym)
    end

    def initialize(round, gender)
      @round = round
      @gender = gender
    end

    def rows(competition)
      @round.team_assessment_rows(competition, @gender)
    end

    def name
      "#{@round.name} #{I18n.t("gender.#{@gender}")}"
    end
  end

  def disciplines
    assessments.pluck(:discipline).uniq.sort
  end

  def team_assessment_rows(competition, gender)
    @team_assessment_rows ||= calculate_rows(competition)
    @team_assessment_rows[gender]
  end

  def aggregate_class
    @aggregate_class ||= Firesport::Series::Handler.team_class_for(aggregate_type)
  end

  def round
    self
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

  def team_participations
    participations.where(type: 'Series::TeamParticipation')
  end

  def person_count
    person_participations.pluck(:person_id).uniq.count
  end

  def person_participations
    participations.where(type: 'Series::PersonParticipation')
  end

  protected

  def calculate_rows(competition)
    rows = {}
    Genderable::KEYS.each do |gender|
      rows[gender] = teams(competition, gender).values.sort
      rows[gender].each { |row| row.calculate_rank!(rows[gender]) }
      rows[gender].each { |_row| aggregate_class.special_sort!(rows[gender]) }
    end
    rows
  end

  def teams(competition, gender)
    teams = {}
    assessments = self.assessments.where(type: 'Series::TeamAssessment')
    Series::TeamParticipation.where(assessment: assessments.gender(gender)).find_each do |participation|
      next if participation.cup.dummy_for_competition.present?
      next unless participation.cup.in?(showable_cups(competition))

      teams[participation.entity_id] ||= aggregate_class.new(self, participation.team, participation.team_number)
      teams[participation.entity_id].add_participation(participation)
    end
    assessments.gender(gender).each do |assessment|
      result = assessment.score_results.find_by(competition:)
      next if result.blank?

      cup  = Series::Cup.find_or_create_today!(self, competition)
      next unless cup.in?(showable_cups(competition))

      rows = result.group_result.rows

      convert_result_rows(rows, gender) do |row, time, points, rank|
        participation = Series::TeamParticipation.new(
          cup:,
          team: row.entity.fire_sport_statistics_team_with_dummy,
          team_number: row.entity.number,
          time:,
          points:,
          rank:,
          assessment:,
        )

        teams[participation.entity_id] ||= aggregate_class.new(self, participation.team, participation.team_number)
        teams[participation.entity_id].add_participation(participation)
      end
    end
    teams
  end
end
