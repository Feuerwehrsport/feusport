# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_factories
#
#  id                       :uuid             not null, primary key
#  best_count               :integer
#  hidden                   :boolean          default(FALSE), not null
#  name                     :string(100)
#  separate_target_times    :boolean
#  shortcut                 :string(50)
#  show_best_of_run         :boolean          default(FALSE), not null
#  single_competitors_first :boolean          default(TRUE), not null
#  status                   :string(50)
#  track                    :integer
#  track_count              :integer
#  type                     :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  before_list_id           :uuid
#  before_result_id         :uuid
#  competition_id           :uuid             not null
#  discipline_id            :uuid             not null
#  session_id               :string(200)      not null
#
# Indexes
#
#  index_score_list_factories_on_before_list_id    (before_list_id)
#  index_score_list_factories_on_before_result_id  (before_result_id)
#  index_score_list_factories_on_competition_id    (competition_id)
#  index_score_list_factories_on_discipline_id     (discipline_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Score::ListFactory < ApplicationRecord
  include Score::ListFactoryDefaults

  STEPS = %i[discipline assessments names tracks results generator generator_params finish create].freeze
  GENERATORS = [
    'Score::ListFactories::GroupOrder',
    'Score::ListFactories::LotteryNumber',
    'Score::ListFactories::Simple',
    'Score::ListFactories::Best',
    'Score::ListFactories::FireRelay',
    'Score::ListFactories::TrackChange',
    'Score::ListFactories::TrackSame',
    'Score::ListFactories::TrackBandable',
  ].freeze

  belongs_to :competition, touch: true
  belongs_to :discipline
  belongs_to :before_list, class_name: 'Score::List'
  belongs_to :before_result, class_name: 'Score::Result'
  has_many :list_factory_assessments, dependent: :destroy
  has_many :assessments, through: :list_factory_assessments
  has_many :result_list_factories, dependent: :destroy
  has_many :results, through: :result_list_factories
  has_many :list_factory_bands, dependent: :destroy
  has_many :bands, through: :list_factory_bands

  default_scope { where.not(status: :create) }

  auto_strip_attributes :name, :shortcut

  schema_validations
  validates :discipline, presence: true
  validates :status, inclusion: { in: STEPS }, allow_nil: true

  validates :assessments, presence: true, if: -> { step_reached?(:names) }
  validate :assessments_possible, if: -> { step_reached?(:names) }
  validates :name, presence: true, if: -> { step_reached?(:tracks) }
  validates :shortcut, presence: true, length: { maximum: 8 }, if: -> { step_reached?(:tracks) }
  validates :track_count, numericality: { only_integer: true, graeter_than: 0 }, if: -> { step_reached?(:results) }
  validates :results, presence: true, if: -> { step_reached?(:generator) }
  validate :type_valid, if: -> { step_reached?(:generator_params) }
  validates :discipline, :before_list, :before_result, :assessments, :results, :bands, same_competition: true

  attr_writer :next_step

  before_save do
    self.status = if status == :generator && next_step == :generator_params && type.constantize.generator_params.empty?
                    :finish
                  else
                    next_step || STEPS[1]
                  end
    self.separate_target_times = discipline.key == 'la' if separate_target_times.nil?
  end
  after_save do
    if saved_change_to_status? && status == :create
      list
      perform
    end
  end

  def self.generators
    @generators ||= GENERATORS.map(&:constantize)
  end

  def possible_types
    self.class.generators.select { |g| g.generator_possible?(discipline) }
  end

  def self.generator_params
    []
  end

  def self.generator_possible?(discipline)
    !discipline.like_fire_relay?
  end

  def possible_type_with_names
    possible_types.map do |type|
      [type.model_name.human, type.to_s]
    end
  end

  def preview_entries_count
    assessment_requests.count
  end

  def preview_run_count
    (preview_entries_count.to_f / track_count).ceil
  end

  def next_step
    @next_step.try(:to_sym)
  end

  def current_step
    status || STEPS[0]
  end

  def status
    super.try(:to_sym)
  end

  def current_step_number
    STEPS.find_index(current_step) || 0
  end

  def next_step_number
    STEPS.find_index(next_step) || (STEPS.length - 1)
  end

  def step_reached?(step)
    next_step_number >= STEPS.find_index(step)
  end

  def perform
    for_run_and_track_for(perform_rows)
  end

  def default_name
    name.presence || begin
      main_name = assessments.count == 1 ? assessments.first.name : discipline.name
      unless discipline.like_fire_relay?
        run = 1
        loop do
          break if competition.score_lists.where(name: "#{main_name} - Lauf #{run}").blank?

          run += 1
        end
        main_name = "#{main_name} - Lauf #{run}"
      end
      main_name
    end
  end

  def list
    @list ||= Score::List.create!(competition:, name:, shortcut:, assessments:, results:,
                                  track_count:, hidden:,
                                  separate_target_times: separate_target_times.nil? ? false : separate_target_times,
                                  show_best_of_run: show_best_of_run.nil? ? false : show_best_of_run)
  end

  protected

  def for_run_and_track_for(rows, tracks = nil)
    tracks = (1..list.track_count) if tracks.nil?
    rows = rows.dup
    run = 0
    transaction do
      loop do
        run += 1
        row = nil
        tracks.each do |track|
          row = rows.shift
          next if row.nil?

          create_list_entry(row, run, track)
        end

        break if row.nil?
        raise 'Something went wrong' if run > 1000
      end
    end
  end

  def assessment_requests
    requests = []
    assessments.each { |assessment| requests += assessment.requests.for_assessment(assessment).to_a }
    if team_shuffle?
      requests.shuffle
    else
      requests.sort_by { |request| request.entity.try(:lottery_number) || -1 }
    end
  end

  def team_shuffle?
    !competition.lottery_numbers?
  end

  def create_list_entry(request, run, track)
    list.entries.create!(
      competition:,
      entity: request.entity,
      run:,
      track:,
      assessment_type: request.assessment_type,
      assessment: request.assessment,
    )
  end

  def perform_rows
    []
  end

  private

  def assessments_possible
    assessments.each do |assessment|
      errors.add(:assessments, :invalid) unless assessment.in?(possible_assessments)
    end
  end

  def type_valid
    errors.add(:type, :invalid) unless type.in?(possible_types.map(&:to_s))
  end
end
