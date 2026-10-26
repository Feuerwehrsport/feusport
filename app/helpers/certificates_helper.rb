# frozen_string_literal: true

module CertificatesHelper
  BROWSER_IMAGE_TYPES = %w[image/png image/jpg image/jpeg image/webp image/gif].freeze

  # Urkunden gehen auch in gesperrten Wettkämpfen (nach der Übertragung), unabhängig von can?(:manage, competition)
  def certificates_allowed?(competition = @competition)
    can?(:create, Certificates::List.new(competition:))
  end

  # Hinweis auf den Import, solange es außer der Beispiel-Vorlage nichts gibt und eigene Vorlagen existieren
  def certificates_import_hint?(competition = @competition)
    return false if competition.certificates_templates.where.not(name: Certificates::Template::EXAMPLE_NAME).exists?

    Certificates::Template.where(importable_for_me: true).accessible_by(current_ability)
                          .where.not(competition:).exists?
  end

  # Hintergrund für Editor und Vorschau: PDF, TIFF und HEIC zeigen Browser nicht an, dafür ein Vorschaubild
  # (bei PDF die erste Seite, über die Active-Storage-Previewer)
  def certificates_background_path(template)
    image = template.image
    return rails_blob_path(image) if image.content_type.in?(BROWSER_IMAGE_TYPES)

    rails_representation_path(image.representation(resize_to_limit: [1240, 1754]))
  end
end
