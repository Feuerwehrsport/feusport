# frozen_string_literal: true

# == Schema Information
#
# Table name: score_results
#
#  id                   :uuid             not null, primary key
#  calculation_method   :integer          default("default"), not null
#  date                 :date
#  forced_name          :string(100)
#  group_assessment     :boolean          default(FALSE), not null
#  group_run_count      :integer          default(8), not null
#  group_score_count    :integer          default(6), not null
#  image_key            :string(10)
#  multi_result_method  :integer          default("disabled"), not null
#  person_tags_excluded :string           default([]), is an Array
#  person_tags_included :string           default([]), is an Array
#  team_tags_excluded   :string           default([]), is an Array
#  team_tags_included   :string           default([]), is an Array
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  assessment_id        :uuid
#  competition_id       :uuid             not null
#
# Indexes
#
#  index_score_results_on_assessment_id   (assessment_id)
#  index_score_results_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (competition_id => competitions.id)
#
class Score::Result < ApplicationRecord
  include Score::Resultable
  include SortableByName

  CALCULATION_METHODS = { default: 0, sum_of_two: 1 }.freeze
  MULTI_RESULT_METHODS = { disabled: 0, sum_of_best: 1, best: 2 }.freeze
  DISCIPLINES = %w[la hl hb zk gs fs other].freeze

  enum :calculation_method, CALCULATION_METHODS, scopes: false, prefix: true
  enum :multi_result_method, MULTI_RESULT_METHODS, scopes: false, prefix: true

  belongs_to :competition, touch: true
  belongs_to :assessment, inverse_of: :results
  has_many :result_lists, dependent: :destroy, inverse_of: :result
  has_many :lists, through: :result_lists
  has_many :result_series_assessments, class_name: 'Score::ResultSeriesAssessment', dependent: :destroy,
                                       inverse_of: :result
  has_many :series_assessments, through: :result_series_assessments, source: :assessment,
                                class_name: 'Series::Assessment'
  has_many :competition_result_references, class_name: 'Score::CompetitionResultReference', dependent: :destroy
  has_many :competition_results, class_name: 'Score::CompetitionResult', through: :competition_result_references
  has_many :result_references, class_name: 'Score::ResultReference', dependent: :destroy, inverse_of: :result
  has_many :result_multi_references, class_name: 'Score::ResultReference', dependent: :destroy,
                                     inverse_of: :multi_result, foreign_key: :multi_result_id
  has_many :results, class_name: 'Score::Result', through: :result_multi_references
  has_many :result_list_factories, class_name: 'Score::ResultListFactory', dependent: :destroy

  delegate :discipline, to: :assessment, allow_nil: true
  delegate :band, to: :assessment, allow_nil: true

  scope :single_disciplines, -> { joins(:assessment).merge(Assessment.single_disciplines) }

  auto_strip_attributes :forced_name

  schema_validations
  before_validation :clean_tags
  validate :useless_team_tags
  validate :useless_person_tags
  validate :discipline_changed, on: :update
  validates :group_run_count, :group_score_count, numericality: { greater_than: 0 }
  validates :assessment, :competition_results, :results, same_competition: true
  validates :assessment, presence: true, if: :multi_result_method_disabled?
  validates :image_key, presence: true, unless: :multi_result_method_disabled?

  def name
    @name ||= forced_name.presence || generated_name
  end
  alias to_label name

  def generated_name
    tags_included = (team_tags_included + person_tags_included).join(', ').presence
    tags_excluded = (team_tags_excluded + person_tags_excluded).join(', ').presence
    tags_excluded = "ohne #{tags_excluded}" if tags_excluded.present?
    [assessment&.name, tags_included, tags_excluded].compact_blank.join(' - ')
  end

  def possible_series_assessments
    series = Series::Assessment.where(discipline: discipline_key)
                               .year(Date.current.year)
    series = series.gender(assessment.band.gender) if assessment&.band.present?
    series
  end

  def single_discipline?
    if multi_result_method_disabled?
      discipline&.single_discipline?
    else
      results.map(&:discipline).all?(&:single_discipline?)
    end
  end

  def single_group_result?
    group_assessment? && single_discipline?
  end

  def rows(*)
    @rows ||= generate_rows.sort
  end

  def out_of_competition_rows
    generate_rows if @out_of_competition_rows.nil?
    @out_of_competition_rows
  end

  def group_result_rows
    @group_result_rows ||= generate_rows(group_result: true).sort
  end

  def person_tags
    @person_tags ||= tags.where(type: 'PersonTag')
  end

  def team_tags
    @team_tags ||= tags.where(type: 'TeamTag')
  end

  def generate_rows(group_result: false)
    return generate_multi_rows unless multi_result_method_disabled?

    out_of_competition_rows = {}
    rows = {}
    lists.each do |list|
      list.entries.not_waiting.each do |list_entry|
        next if list_entry.assessment != assessment

        entity = list_entry.entity
        entity = entity.team if group_result && entity.is_a?(TeamRelay)
        next unless use?(entity)

        if list_entry.out_of_competition?
          if out_of_competition_rows[entity.id].nil?
            out_of_competition_rows[entity.id] = Score::ResultRow.new(entity, self)
          end
          out_of_competition_rows[entity.id].add_list(list_entry)
        else
          rows[entity.id] = Score::ResultRow.new(entity, self) if rows[entity.id].nil?
          rows[entity.id].add_list(list_entry)
        end
      end
    end
    @out_of_competition_rows = out_of_competition_rows.values
    rows.values
  end

  def generate_multi_rows
    rows = {}
    results.each do |result|
      result.rows.select(&:valid?).each do |result_row|
        if rows[result_row.entity.id].nil?
          rows[result_row.entity.id] = Score::MultiResultRow.new(result_row.entity, self)
        end
        rows[result_row.entity.id].add_result_row(result_row)
      end
    end
    @out_of_competition_rows = []
    if multi_result_method_sum_of_best?
      rows.values.select { |row| row.result_rows.count == results.count }
    elsif multi_result_method_best?
      rows.values
    else
      []
    end
  end

  def group_result
    @group_result ||= Score::GroupResult.new(self)
  end

  def discipline_key
    image_key.presence || assessment&.discipline&.key
  end

  protected

  def use?(entity)
    case entity
    when TeamRelay
      entity.team.include_tags?(team_tags_included) && entity.team.exclude_tags?(team_tags_excluded)
    when Team
      entity.include_tags?(team_tags_included) && entity.exclude_tags?(team_tags_excluded)
    when Person
      entity.include_tags?(person_tags_included) && entity.exclude_tags?(person_tags_excluded) &&
        (team_tags_included.blank? || entity.team&.include_tags?(team_tags_included)) &&
        (team_tags_excluded.blank? || entity.team&.exclude_tags?(team_tags_excluded))
    else
      false
    end
  end

  def clean_tags
    self.team_tags_included = (team_tags_included || []).select { |tag| tag.in?(band.team_tags) }
    self.team_tags_excluded = (team_tags_excluded || []).select { |tag| tag.in?(band.team_tags) }
    self.person_tags_included = (person_tags_included || []).select { |tag| tag.in?(band.person_tags) }
    self.person_tags_excluded = (person_tags_excluded || []).select { |tag| tag.in?(band.person_tags) }
  end

  def useless_team_tags
    return unless team_tags_included.any? { |tag| tag.in?(team_tags_excluded) }

    errors.add(:team_tags_included, :invalid)
    errors.add(:team_tags_excluded, :invalid)
  end

  def useless_person_tags
    return unless person_tags_included.any? { |tag| tag.in?(person_tags_excluded) }

    errors.add(:person_tags_included, :invalid)
    errors.add(:person_tags_excluded, :invalid)
  end

  def discipline_changed
    return unless assessment_changed?

    before_discipline = Assessment.find_by(id: assessment_id_was)&.discipline
    return if before_discipline == discipline

    errors.add(:assessment, :discipline_changed)
  end
end
