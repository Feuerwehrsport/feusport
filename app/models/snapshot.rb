# frozen_string_literal: true

# == Schema Information
#
# Table name: snapshots
#
#  id             :uuid             not null, primary key
#  highlight      :boolean          default(FALSE), not null
#  processed      :boolean          default(FALSE), not null
#  title          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#
# Indexes
#
#  index_snapshots_on_competition_id  (competition_id)
#  index_snapshots_on_highlight       (highlight)
#  index_snapshots_on_processed       (processed)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Snapshot < ApplicationRecord
  PRODUCTION_VARIANTS = {
    display: {
      method: :resize_to_limit,
      size: [2000, 2000],
      quality: 85,
    }.freeze,
    home: {
      method: :resize_to_fill,
      size: [500, 500],
      quality: 85,
    }.freeze,
    thumb_default: {
      method: :resize_to_fill,
      size: [400, 300],
      quality: 85,
    }.freeze,
    thumb_mini: {
      method: :resize_to_fill,
      size: [100, 100],
      quality: 85,
    }.freeze,
    thumb_preview: {
      method: :resize_to_fill,
      size: [200, 200],
      quality: 85,
    }.freeze,
  }.freeze

  belongs_to :competition

  has_one_attached :file

  auto_strip_attributes :title

  schema_validations
  validates :file, presence: true,
                   blob: { content_type: ['image/jpg', 'image/jpeg'], size_range: 1..(20.megabytes) }
  validates :competition, max_entries: { reverse_key: :snapshots, max: 15, add_to: :file }

  after_destroy :remove_nginx_variants
  after_commit :unset_other_highlights, if: :highlight?
  after_commit :enqueue_resize, on: :create

  def self.variant(key)
    config = PRODUCTION_VARIANTS[key]
    {
      config[:method] => config[:size],
      saver: { quality: config[:quality] },
    }
  end

  def self.for_home
    Snapshot.where(highlight: true).order(Arel.sql('RANDOM()')).first
  end

  def other_highlights
    competition.snapshots.where.not(id:).where(highlight: true)
  end

  def variant_path(key)
    if processed?
      "/uploads/snapshots/#{id}/#{key}.avif"
    else
      file.variant(Snapshot.variant(key))
    end
  end

  def nginx_base_dir
    @nginx_base_dir ||= Rails.public_path.join('uploads/snapshots', id.to_s)
  end

  private

  def unset_other_highlights
    other_highlights.update_all(highlight: false)
  end

  def enqueue_resize
    VariantJob.perform_later(self)
  end

  def remove_nginx_variants
    FileUtils.rm_rf(nginx_base_dir)
  end

  class VariantJob < ApplicationJob
    queue_with_priority 20 # unwichtig

    def perform(snapshot)
      PRODUCTION_VARIANTS.each_key { snapshot.file.variant(Snapshot.variant(it)).processed }

      NginxVariantsJob.perform_later(snapshot)
    end
  end

  class RemoveVariantJob < ApplicationJob
    queue_with_priority 40 # unwichtiger

    def perform(snapshot)
      PRODUCTION_VARIANTS.each_key { snapshot.file.variant(Snapshot.variant(it)).destroy }
    end
  end

  class NginxVariantsJob < ApplicationJob
    queue_with_priority 30 # unwichtiger

    def perform(snapshot)
      source_path = ActiveStorage::Blob.service.path_for(snapshot.file.key)

      FileUtils.mkdir_p(snapshot.nginx_base_dir)

      PRODUCTION_VARIANTS.each do |key, config|
        ImageProcessing::Vips
          .source(source_path)
          .send(config[:method], *config[:size])
          .convert('avif')
          .saver(quality: config[:quality])
          .call(destination: snapshot.nginx_base_dir.join("#{key}.avif").to_s)
      end

      snapshot.update!(processed: true)
      RemoveVariantJob.set(wait: 10.seconds).perform_later
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
