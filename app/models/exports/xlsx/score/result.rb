# frozen_string_literal: true

Exports::Xlsx::Score::Result = Struct.new(:result) do
  include Exports::Xlsx::Base
  include Exports::ScoreResults

  def perform
    single_table
    group_table if result.single_group_result?
  end

  protected

  def bold
    @bold = workbook.styles.add_style(b: true)
  end

  def italic
    @italic = workbook.styles.add_style(i: true)
  end

  def single_table
    add_worksheet(result.name) do |sheet|
      build_data_rows(result, false).each { |row| sheet.add_row(row) }
    end
  end

  def group_table
    add_worksheet('Mannschaftswertung') do |sheet|
      build_group_data_rows(result).each { |row| sheet.add_row(row) }

      sheet.add_row []
      sheet.add_row []
      build_group_data_details_rows(result).each do |team_result|
        sheet.add_row [team_result.team.full_name, team_result.result_entry.human_time], style: bold
        team_result.rows_in.each { |row| sheet.add_row(row) }
        team_result.rows_out.each { |row| sheet.add_row(row, style: italic) }

        sheet.add_row []
        sheet.add_row []
      end
    end
  end
end
