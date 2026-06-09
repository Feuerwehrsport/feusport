# frozen_string_literal: true

# == Schema Information
#
# Table name: snapshots
#
#  id             :uuid             not null, primary key
#  highlight      :boolean          default(FALSE), not null
#  title          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#
# Indexes
#
#  index_snapshots_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Snapshot < ApplicationRecord
  DISPLAY_VARIANT = {
    resize_to_limit: [2000, 2000],
    saver: { quality: 85 },
  }.freeze
  THUMB_DEFAULT_VARIANT = {
    resize_to_fill: [400, 300],
    saver: { quality: 85 },
  }.freeze
  THUMB_MINI_VARIANT = {
    resize_to_fill: [100, 100],
    saver: { quality: 85 },
  }.freeze
  THUMB_PREVIEW_VARIANT = {
    resize_to_fill: [200, 200],
    saver: { quality: 85 },
  }.freeze

  belongs_to :competition

  has_one_attached :file

  auto_strip_attributes :title

  schema_validations
  validates :file, presence: true,
                   blob: { content_type: ['image/jpg', 'image/jpeg'], size_range: 1..(20.megabytes) }
  validates :competition, max_entries: { reverse_key: :snapshots, max: 15, add_to: :file }

  after_commit :unset_other_highlights, if: :highlight?
  after_commit :enqueue_resize, on: :create

  def other_highlights
    competition.snapshots.where.not(id:).where(highlight: true)
  end

  private

  def unset_other_highlights
    other_highlights.update_all(highlight: false)
  end

  def enqueue_resize
    VariantJob.perform_later(self)
  end

  class VariantJob < ApplicationJob
    queue_with_priority 20 # unwichtig

    def perform(snapshot)
      snapshot.file.variant(Snapshot::THUMB_DEFAULT_VARIANT).processed
      snapshot.file.variant(Snapshot::THUMB_MINI_VARIANT).processed
      snapshot.file.variant(Snapshot::THUMB_PREVIEW_VARIANT).processed
      snapshot.file.variant(Snapshot::DISPLAY_VARIANT).processed
    end
  end

  class ReminderJob < ApplicationJob
    discard_on ActiveJob::DeserializationError

    def perform
      competitions.first&.tap do |competition|
        unless competition.snapshots.exists?(highlight: true)
          CompetitionMailer.with(competition:).snapshot_reminder.deliver_later
        end
        competition.update!(snapshot_reminder_sent: Time.current)
      end
    end

    def competitions
      Competition.where(snapshot_reminder_sent: nil).where(Competition.arel_table[:date].lt(Date.current))
    end
  end
end
