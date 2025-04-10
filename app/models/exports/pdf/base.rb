# frozen_string_literal: true

module Exports::Pdf::Base
  include Exports::Base
  extend ActiveSupport::Concern

  class_methods do
    def perform(*args)
      instance = new(*args)
      instance.unicode_perform
      instance
    end
  end

  def bytestream
    @bytestream ||= pdf.render
  end

  def unicode_perform
    font_path = Rails.root.join('app/assets/fonts')
    pdf.font_families.update(
      'Arial' => {
        normal: "#{font_path}/Arial.ttf",
        bold: "#{font_path}/Arial_Bold.ttf",
        italic: "#{font_path}/Arial_Italic.ttf",
        bold_italic: "#{font_path}/Arial_Bold_Italic.ttf",
      },
    )

    pdf.font('Arial')
    perform
  end

  def pdf
    @pdf ||= Prawn::Document.new(default_prawn_options)
  end

  def filename
    "#{filename_base}.pdf"
  end

  def default_prawn_options
    {
      page_size: 'A4',
      info: { Title: export_title },
    }
  end

  def pdf_discipline_image(discipline_key, width:, at:)
    pdf.image(Rails.root.join('app', 'assets', 'images', 'disciplines', "#{discipline_key}.png"),
              width:, at:)
  end

  protected

  def pdf_header(name, discipline_key: nil, date: nil, force_name: false)
    date ||= competition.date
    headline_y = pdf.cursor
    pdf.text(name, align: :center, size: 17)
    pdf.text([competition.name, l(date)].join(' - '), align: :center, size: 15) unless force_name
    return if discipline_key.blank?

    pdf_discipline_image(discipline_key, width: 30, at: [10, headline_y])
    pdf.move_down 10
  end

  def pdf_footer(name: nil, no_page_count: nil, date: nil, force_name: false)
    date ||= competition.date
    base_footer_line = force_name ? [] : [competition.name, l(date)]
    base_footer_line.push(name) if name.present?

    pdf.page_count.times do |page|
      pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom - 2], width: pdf.bounds.width, height: 30) do
        pdf.go_to_page(page + 1)

        footer_line = base_footer_line.dup
        footer_line.push("Seite #{page + 1} von #{pdf.page_count}") unless no_page_count

        pdf.text(footer_line.join(' - '), align: :center, size: 8)
      end
    end
  end

  def pdf_default_row_colors
    color = 267
    (1..2).map do
      color -= 12
      color.to_s(16) * 3
    end
  end
end
