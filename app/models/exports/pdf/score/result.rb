# frozen_string_literal: true

Exports::Pdf::Score::Result = Struct.new(:result, :only) do
  include Exports::Pdf::Base
  include Exports::ScoreResults

  def perform
    single_table if only != 'group_assessment'
    group_table if only != 'single_competitors' && result.single_group_result?
    pdf_footer(name: result.name, date: result.date)
  end

  protected

  def single_table
    pdf_header(result.name, discipline_key: result.discipline_key, date: result.date)

    pdf.table(build_data_rows(result, true, pdf: true),
              header: true,
              row_colors: pdf_default_row_colors,
              width: pdf.bounds.width,
              cell_style: { align: :center, size: 10 }) do
      row(0).style(font_style: :bold, size: 10)
      column(-1).style(font_style: :bold)
    end
  end

  def group_table
    pdf.start_new_page if only.nil?
    pdf_header("#{result.name} - Mannschaftswertung", discipline_key: result.discipline_key, date: result.date)

    pdf.table(build_group_data_rows(result),
              header: true,
              row_colors: pdf_default_row_colors,
              column_widths: [60, 200, 80],
              position: :center,
              cell_style: { align: :center, size: 10 }) do
      row(0).style(font_style: :bold, size: 11)
    end

    pdf.start_new_page

    build_group_data_details_rows(result).each { |team_result| team_result_table(team_result) }
  end

  def team_result_table(team_result)
    data = [[team_result.team.full_name, team_result.result_entry.human_time]]
    team_result.rows_in.each { |row| data.push(row) }
    team_result.rows_out.each { |row| data.push(row) }

    pdf.table(data,
              header: true,
              column_widths: [200, 80],
              position: :center) do
      team_result.rows_in.each_index { |i| row(i + 1).style(size: 10) }
      team_result.rows_out.each_index { |i| row(i + 1 + team_result.rows_in.size).style(font_style: :italic, size: 8) }
      column(0).style(align: :right)
      column(1).style(align: :center)
      row(0).style(align: :center, font_style: :bold)
    end

    pdf.move_down 10
  end
end
