# frozen_string_literal: true

Exports::Pdf::Flyer = Struct.new(:competition) do
  include Exports::Pdf::Base

  def perform
    pdf.text(competition.flyer_headline, align: :center, size: 20)
    competition.disciplines.each_with_index do |discipline, index|
      pdf.image(Rails.root.join("app/assets/images/disciplines/#{discipline.key}.png"),
                width: 50, at: [10, 700 - (index * 60)])
    end
    pdf.move_down(12)

    pdf.text_box(competition.flyer_content, at: [90, 600], align: :left, width: 500, size: 16)

    pdf.text_box(competition_url, at: [26, 345], align: :center,
                                  width: 500, size: 20)
    pdf.print_qr_code(competition_url, extent: 300, pos: [126, 320], level: :h)

    pdf_footer(no_page_count: true)
  end

  def export_title
    "#{competition.date} - #{competition.name}"
  end

  def competition_url
    Rails.application.routes.url_helpers
         .competition_show_url(Rails.application.config.default_url_options.merge(
                                 year: competition.year,
                                 slug: competition.slug,
                               ))
  end
end
