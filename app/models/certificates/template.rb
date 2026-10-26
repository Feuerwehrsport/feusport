# frozen_string_literal: true

# == Schema Information
#
# Table name: certificates_templates
#
#  id                    :uuid             not null, primary key
#  importable_for_me     :boolean          default(TRUE), not null
#  importable_for_others :boolean          default(FALSE), not null
#  name                  :string(200)      not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  competition_id        :uuid             not null
#
# Indexes
#
#  index_certificates_templates_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
require 'fileutils'

class Certificates::Template < ApplicationRecord
  belongs_to :competition, touch: true
  has_many :text_fields, class_name: 'Certificates::TextField', inverse_of: :template, dependent: :destroy

  # Hintergründe: PNG/JPG nutzt Prawn direkt, andere Rasterformate werden zu JPG umgewandelt, ein PDF wird als
  # Vektor unter die Urkunden gelegt (combine_pdf). Kein SVG (Skripte, externe Verweise).
  PRAWN_IMAGE_TYPES = %w[image/png image/jpg image/jpeg].freeze
  CONVERTED_IMAGE_TYPES = %w[image/webp image/gif image/tiff image/heic image/heif].freeze
  PDF_TYPE = 'application/pdf'
  EXAMPLE_NAME = 'Beispiel-Urkunde (Vorlage)'
  A4_PORTRAIT = [595.28, 841.89].freeze

  schema_validations
  validates :image, blob: { content_type: [*PRAWN_IMAGE_TYPES, *CONVERTED_IMAGE_TYPES, PDF_TYPE],
                            size_range: 1..(10.megabytes) }
  validate :validate_pdf_image
  validates :font, :font2,
            blob: { content_type: ['ttf', 'application/font-sfnt', 'font/ttf'], size_range: 1..(10.megabytes) }

  %i[image font font2].each do |file|
    has_one_attached file

    define_method(:"#{file}_path") do
      return unless public_send(file).attached?

      orig_src = ActiveStorage::Blob.service.path_for(public_send(file).key)
      return unless File.file?(orig_src)

      orig_dir = File.dirname(orig_src)
      temp_src = File.join(orig_dir, public_send(file).filename.to_s)
      FileUtils.cp(orig_src, temp_src)
      temp_src
    end
    define_method(:"#{file}_hint") do
      "Zur Zeit: #{public_send(file).filename}" if public_send(file).attached?
    end
  end

  auto_strip_attributes :name

  # Eigene (importable_for_me, über die Ability) und für alle freigegebene Vorlagen
  def self.importable(ability)
    where(importable_for_others: true).or(where(id: where(importable_for_me: true).accessible_by(ability).select(:id)))
  end

  def image_pdf?
    image.attached? && image.content_type == PDF_TYPE
  end

  # Für pdf.image in Prawn: Pfad (PNG/JPG) oder JPG-Daten (andere Rasterformate), nil bei PDF
  def background_image_source
    return if !image.attached? || image_pdf?
    return image_path if image.content_type.in?(PRAWN_IMAGE_TYPES)

    StringIO.new(image.variant(format: :jpg, saver: { quality: 92 }).processed.download)
  end

  # Seite für combine_pdf, nur bei PDF-Hintergrund
  def background_pdf_page
    CombinePDF.parse(image.download).pages.first if image_pdf?
  end

  accepts_nested_attributes_for :text_fields, allow_destroy: true

  def self.create_example(competition)
    template = create(competition:, name: EXAMPLE_NAME, importable_for_me: false)
    template.update(
      text_fields_attributes: [
        {
          left: 97, top: 497,
          width: 400, height: 50,
          size: 36,
          key: 'rank_with_rank2',
          align: 'center',
          font: 'bold'
        },
        {
          left: 97, top: 603,
          width: 400, height: 50,
          size: 16,
          key: 'time_other_long',
          align: 'center'
        },
        {
          left: 97, top: 687,
          width: 400, height: 50,
          size: 36,
          key: 'team_name',
          align: 'center',
          font: 'bold'
        },
        {
          left: 42, top: 166,
          width: 250, height: 30,
          size: 16,
          key: 'competition_name',
          align: 'center'
        },
        {
          left: 42, top: 96,
          width: 250, height: 30,
          size: 16,
          key: 'date',
          align: 'center'
        },
        {
          left: 42, top: 131,
          width: 250, height: 30,
          size: 16,
          key: 'place',
          align: 'center'
        },
      ],
    )
  end

  def duplicate_to(new_competition)
    duplicate = dup
    duplicate.competition = new_competition
    duplicate.name = "#{duplicate.name} (Duplikat von »#{I18n.l(competition.date)} - #{competition.name}«)"
    duplicate.image.attach(image.blob) if image.attached?
    duplicate.font.attach(font.blob) if font.attached?
    duplicate.font2.attach(font2.blob) if font2.attached?

    duplicate.save

    text_fields.each do |text_field|
      duplicate.text_fields.create(text_field.attributes.except('id', 'created_at', 'updated_at'))
    end

    duplicate
  end

  def long_name
    "(#{I18n.l(competition.date)} - #{competition.name}) #{name}"
  end

  private

  # Nur beim Hochladen prüfen: genau eine Seite, A4 hochkant (Urkunden sind immer A4 hochkant)
  def validate_pdf_image
    return unless image_pdf? && attachment_changes['image']

    pages = CombinePDF.parse(uploaded_image_data).pages
    return errors.add(:image, :pdf_single_page) unless pages.one?

    errors.add(:image, :pdf_a4_portrait) unless a4_portrait?(pages.first)
  rescue CombinePDF::ParsingError
    errors.add(:image, :invalid)
  end

  def a4_portrait?(page)
    x0, y0, x1, y1 = page.mediabox
    width = (x1 - x0).abs
    height = (y1 - y0).abs
    width, height = height, width if page[:Rotate].to_i.abs % 180 == 90
    (width - A4_PORTRAIT[0]).abs < 2 && (height - A4_PORTRAIT[1]).abs < 2
  end

  # Hochgeladene Datei oder (beim Duplizieren) vorhandener Blob
  def uploaded_image_data
    attachable = attachment_changes['image'].attachable
    return attachable.download if attachable.is_a?(ActiveStorage::Blob)

    attachable.read.tap { attachable.rewind }
  end
end
