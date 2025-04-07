# frozen_string_literal: true

# == Schema Information
#
# Table name: series_assessments
#
#  id         :bigint           not null, primary key
#  discipline :string(2)        not null
#  gender     :integer          not null
#  name       :string           default(""), not null
#  type       :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  round_id   :integer          not null
#
class Series::Assessment < ApplicationRecord
  include Genderable
  include Series::Importable

  belongs_to :round, class_name: 'Series::Round', inverse_of: :assessments
  has_many :cups, through: :round, class_name: 'Series::Cup'
  has_many :participations, class_name: 'Series::Participation', dependent: :destroy, inverse_of: :assessment
  has_many :assessment_score_results, class_name: 'Score::ResultSeriesAssessment', dependent: :destroy,
                                      inverse_of: :assessment
  has_many :score_results, through: :assessment_score_results, source: :result

  scope :round, ->(round_id) { where(round_id:) }
  scope :year, ->(year) { joins(:round).where(series_rounds: { year: }) }
  scope :round_name, ->(round_name) { joins(:round).where(series_rounds: { name: round_name }) }

  validates :round, :discipline, :gender, presence: true
  schema_validations

  def rows(competition)
    @rows ||= calculate_rows(competition)
  end

  def aggregate_class
    @aggregate_class ||= Firesport::Series::Handler.person_class_for(round.aggregate_type)
  end

  def to_label
    "#{name} (#{round.name} #{round.year})"
  end

  def discipline_model
    Discipline.types_with_key[discipline.to_sym].new
  end

  def score_result_label
    "#{self.class.model_name.human}: #{to_label}"
  end

  protected

  def calculate_rows(competition)
    @rows = entities(competition).values.sort
    @rows.each { |row| row.calculate_rank!(@rows) }
  end

  def entities(competition)
    entities = {}
    participations.each do |participation|
      entities[participation.entity_id] ||= aggregate_class.new(round, participation.entity)
      entities[participation.entity_id].add_participation(participation)
    end
    result = score_results.find_by(competition:)
    if result.present?
      cup = Series::Cup.find_or_create_today!(round, result.competition)
      convert_result_rows(result.rows, gender) do |row, time, points, rank|
        participation = Series::PersonParticipation.new(
          cup:,
          person: row.entity.fire_sport_statistics_person_with_dummy,
          time:,
          points:,
          rank:,
        )

        entities[participation.entity_id] ||= aggregate_class.new(round, participation.entity)
        entities[participation.entity_id].add_participation(participation)
      end
    end
    entities
  end
end
