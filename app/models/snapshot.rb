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
    ResizeJob.perform_later(self)
  end

  class ResizeJob < ApplicationJob
    MAX_DIMENSION = 2000
    QUALITY = 85

    queue_with_priority 20 # unwichtig

    def perform(snapshot)
      require 'image_processing/vips'

      source_path = ActiveStorage::Blob.service.path_for(snapshot.file.key)
      processed = ImageProcessing::Vips
                  .source(source_path)
                  .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
                  .convert('jpg')
                  .saver(quality: QUALITY)
                  .call

      snapshot.file.attach(
        io: processed,
        filename: "#{snapshot.file.filename.base}.jpg",
        content_type: 'image/jpeg',
      )
      snapshot.file.blob.analyze
    end
  end
end
