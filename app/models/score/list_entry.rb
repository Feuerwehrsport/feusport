# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_entries
#
#  id                :uuid             not null, primary key
#  assessment_type   :integer          default("group_competitor"), not null
#  entity_type       :string(50)       not null
#  result_type       :string(20)       default("waiting"), not null
#  run               :integer          not null
#  time              :integer
#  time_left_target  :integer
#  time_right_target :integer
#  track             :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  assessment_id     :uuid             not null
#  competition_id    :uuid             not null
#  entity_id         :uuid             not null
#  list_id           :uuid             not null
#
# Indexes
#
#  index_score_list_entries_on_assessment_id   (assessment_id)
#  index_score_list_entries_on_competition_id  (competition_id)
#  index_score_list_entries_on_list_id         (list_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (list_id => score_lists.id)
#
class Score::ListEntry < ApplicationRecord
  include Score::ResultEntrySupport

  BEFORE_CHECK_METHODS =
    %i[result_type edit_second_time edit_second_time_left_target edit_second_time_right_target].freeze
  edit_time(:time_left_target)
  edit_time(:time_right_target)

  belongs_to :competition, touch: true
  belongs_to :list, class_name: 'Score::List', inverse_of: :entries
  belongs_to :entity, polymorphic: true
  belongs_to :assessment

  enum :assessment_type, { group_competitor: 0, single_competitor: 1, out_of_competition: 2 }

  validates :track, :run, numericality: { greater_than: 0 }
  validates :track, numericality: { less_than_or_equal_to: :track_count }
  validate :check_changed_while_editing, on: :update
  validates :list, :assessment, same_competition: true

  schema_validations
  before_validation do
    if list&.separate_target_times?
      self.time = ([time_left_target, time_right_target].max if time_left_target.present? && time_right_target.present?)
    end
  end

  delegate :track_count, to: :list

  scope :result_valid, -> { where(result_type: :valid) }
  scope :not_waiting, -> { where.not(result_type: :waiting) }
  scope :waiting, -> { where(result_type: :waiting) }
  default_scope { order(:run, :track) }

  after_commit(on: :update) do
    if previous_changes.keys.intersection(
      %w[competition_id list_id entity_type entity_id assessment_type assessment_id track run],
    ).any?
      ScoreListChannel::Updater.safe_perform_later(list,
                                                   tab_session_id: TabSessionIdSupport::Current.tab_session_id)
    elsif previous_changes.keys.intersection(%w[result_type time time_left_target time_right_target]).any?
      ScoreListChannel::Updater.safe_perform_later(list,
                                                   tab_session_id: TabSessionIdSupport::Current.tab_session_id, run:)
    end
  end
  after_commit(on: %i[create destroy]) do
    ScoreListChannel::Updater.safe_perform_later(list, tab_session_id: TabSessionIdSupport::Current.tab_session_id)
  end

  BEFORE_CHECK_METHODS.each do |method_name|
    define_method(:"#{method_name}_before") do
      send(method_name)
    end
    attr_writer :"#{method_name}_before"
  end
  attr_accessor :changed_while_editing

  def self.insert_random_values
    where(result_type: :waiting).find_each do |l|
      if l.list.separate_target_times?
        l.update!(time_with_valid_calculation: rand(1900..2300),
                  time_left_target: rand(1900..2300), time_right_target: rand(1900..2300))
      else
        l.update!(time_with_valid_calculation: rand(1900..2300))
      end
    end
  end

  def run_and_track_sortable
    "#{run.to_s.rjust(3, '0')}-#{track.to_s.rjust(3, '0')}"
  end

  def overview
    "#{list.name}; #{entity.full_name}: #{long_human_time}"
  end

  private

  def check_changed_while_editing
    datebase_entry = self.class.find(id)
    changed_while_editing = BEFORE_CHECK_METHODS.any? do |method_name|
      value_before = instance_variable_get(:"@#{method_name}_before")
      value_before.present? && value_before.to_s != datebase_entry.send(method_name).to_s
    end

    errors.add(:changed_while_editing) if changed_while_editing
  end
end
