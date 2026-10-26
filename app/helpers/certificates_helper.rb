# frozen_string_literal: true

module CertificatesHelper
  BROWSER_IMAGE_TYPES = %w[image/png image/jpg image/jpeg image/webp image/gif].freeze

  # Hintergrund für Editor und Vorschau: PDF, TIFF und HEIC zeigen Browser nicht an, dafür ein Vorschaubild
  # (bei PDF die erste Seite, über die Active-Storage-Previewer)
  def certificates_background_path(template)
    image = template.image
    return rails_blob_path(image) if image.content_type.in?(BROWSER_IMAGE_TYPES)

    rails_representation_path(image.representation(resize_to_limit: [1240, 1754]))
  end
end
