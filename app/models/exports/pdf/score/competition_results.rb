# frozen_string_literal: true

Exports::Pdf::Score::CompetitionResults = Struct.new(:competition, :results) do
  include Exports::Pdf::Base
  include Exports::CompetitionResults

  def perform
    results.each_with_index do |result, index|
      pdf.start_new_page unless index.zero?
      pdf_header("Gesamtwertung - #{result.name}")

      pdf.font_size = 10
      pdf.table(table_data(result),
                header: true,
                width: pdf.bounds.width,
                cell_style: { align: :center },
                row_colors: pdf_default_row_colors) do
        row(0).style(font_style: :bold)
      end
    end

    pdf_footer(name: export_title)
  end

  protected

  def default_prawn_options
    super.merge(page_layout: :landscape)
  end
end
