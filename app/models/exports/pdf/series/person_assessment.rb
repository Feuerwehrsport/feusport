# frozen_string_literal: true

Exports::Pdf::Series::PersonAssessment = Struct.new(:config, :competition) do
  include Exports::Pdf::Base

  def export_title
    config.round_full_name
  end

  def default_prawn_options
    super.merge(page_layout: :landscape)
  end

  def perform
    inner_config = config
    pdf_header(config.round_full_name, force_name: true)
    pdf.table(index_export_data,
              header: true,
              row_colors: pdf_default_row_colors,
              width: pdf.bounds.width,
              cell_style: { align: :center, size: 9 }) do
      row(0).style(align: :center, font_style: :bold)
      column(0).style(size: 10)
      column(1).style(size: 10)
      column(2).style(size: 10)

      inner_config.show_columns_config.each_with_index do |_col, index|
        column((index + 1) * -1).style(size: 10)
      end
    end
    pdf_footer(name: config.round_full_name, force_name: true)
  end

  protected

  def index_export_data
    headline = %w[Platz Name Vorname]
    config.round.showable_cups(competition).each do |cup|
      headline.push(cup.competition_place)
    end

    config.show_columns_config.each do |col|
      headline.push(col[:name])
    end

    data = [headline]

    config.rows(competition).each do |row|
      line = [row.rank, row.person.last_name, row.person.first_name]
      config.round.showable_cups(competition).each do |cup|
        line.push(row.participation_for_cup(cup)&.result_entry_with_points&.to_s)
      end

      config.show_columns_config.each do |col|
        line.push(row.public_send(col[:method]))
      end

      data.push(line)
    end
    data
  end
end
