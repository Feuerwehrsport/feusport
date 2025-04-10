# frozen_string_literal: true

Exports::Pdf::Score::List = Struct.new(:list, :more_columns) do
  include Exports::Pdf::Base
  include Exports::ScoreLists

  delegate :competition, to: :list

  def perform
    pdf_header(export_title, discipline_key: list.discipline.key, date: list.date)

    lines = show_export_data(list, more_columns:, pdf: true)
    list_track_count = list.track_count

    lines_per_page = (32 / list_track_count) * list_track_count
    headline = lines.shift
    first = true

    loop do
      current_lines = lines.shift(lines_per_page)
      break if current_lines.blank?

      pdf.start_new_page unless first
      first = false

      pdf.font_size = 10

      pdf.table([headline] + current_lines,
                header: true,
                row_colors: pdf_row_colors,
                width: pdf.bounds.width,
                cell_style: { align: :center },
                column_widths:) do
        row(0).style(font_style: :bold, border_widths: [1, 1, 2, 1])
        line = 0
        loop do
          line += list_track_count
          break if line > row_length

          row(line).style(border_widths: [1, 1, 2, 1])
        end
      end
      pdf.font_size = 12
    end

    pdf_footer(name: export_title, date: list.date)
  end

  def filename_base
    parts = [export_title]
    parts.push('kampfrichter') if more_columns
    parts.join('-').parameterize
  end

  protected

  def column_widths
    @column_widths ||= begin
      widths = { 0 => 35, 1 => 35, -1 => 50 }
      widths[2] = 35 if competition.show_bib_numbers? && list.single_discipline?
      if more_columns
        widths[-1] = 40
        widths[-2] = 40
      end
      widths[-3] = 40 if more_columns
      if list.separate_target_times?
        widths[-1] = 40
        widths[-2] = 40
      end
      widths
    end
  end

  def pdf_row_colors
    color = 264
    (1..list.track_count).map do
      color -= 9
      color.to_s(16) * 3
    end
  end
end
