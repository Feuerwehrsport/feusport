# frozen_string_literal: true

# == Schema Information
#
# Table name: score_lists
#
#  id                        :uuid             not null, primary key
#  date                      :date
#  hidden                    :boolean          default(FALSE), not null
#  name                      :string(100)      default(""), not null
#  separate_target_times     :boolean          default(FALSE), not null
#  shortcut                  :string(50)       default(""), not null
#  show_best_of_run          :boolean          default(FALSE), not null
#  show_multiple_assessments :boolean          default(TRUE), not null
#  track_count               :integer          default(2), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  competition_id            :uuid             not null
#
# Indexes
#
#  index_score_lists_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Score::List < ApplicationRecord
  include SortableByName

  belongs_to :competition, touch: true
  has_many :list_assessments, dependent: :destroy
  has_many :assessments, through: :list_assessments
  has_many :result_lists, dependent: :destroy
  has_many :results, through: :result_lists
  has_many :entries, -> { order(:run).order(:track) }, class_name: 'Score::ListEntry', dependent: :destroy,
                                                       inverse_of: :list

  default_scope { order(:name) }
  auto_strip_attributes :name, :shortcut

  after_touch do
    results.each { |result| ScoreResultChannel::Updater.safe_perform_later(result) }
  end

  schema_validations
  validates :track_count, numericality: { greater_than: 0 }
  validates :assessments, :results, same_competition: true
  accepts_nested_attributes_for :entries, allow_destroy: true

  def next_free_track
    last_entry = entries.last
    run = last_entry.try(:run) || 1
    track = last_entry.try(:track) || 0
    track += 1
    if track > track_count
      track = 1
      run += 1
    end
    [run, track]
  end

  def discipline
    assessments&.first&.discipline
  end

  def single_discipline?
    @single_discipline ||= discipline&.single_discipline?
  end

  def multiple_assessments?
    @multiple_assessments ||= assessments.count > 1
  end

  def discipline_klass
    if single_discipline?
      Person
    elsif assessments&.first&.like_fire_relay?
      TeamRelay
    else
      Team
    end
  end

  def column_count
    @column_count ||= if single_discipline?
                        competition.show_bib_numbers? ? 7 : 6
                      else
                        4
                      end
  end
end
