# frozen_string_literal: true

Exports::Pdf::Series::Round = Struct.new(:round, :competition) do
  include Exports::Pdf::Base

  def export_title
    round.name
  end

  def default_prawn_options
    super.merge(page_layout: :landscape)
  end

  def perform
    first = true

    round.team_assessments_configs.each do |config|
      rows = config.rows(competition)
      next if rows.blank?

      pdf.start_new_page unless first
      first = false

      pdf_header("#{round.name} - Mannschaftswertung #{config.name}", force_name: true)
      pdf.table(index_export_data(config, rows),
                header: true,
                row_colors: pdf_default_row_colors,
                width: pdf.bounds.width) do
        row(0).style(align: :center, font_style: :bold)
        column(0).style(align: :center)
        column(1).style(align: :center)

        config.show_columns_config.each_with_index do |_col, index|
          column((index + 1) * -1).style(align: :center)
        end
      end
    end
    pdf_footer(name: round.name, force_name: true)
  end

  protected

  def index_export_data(config, rows)
    headline = %w[Platz Team]
    round.showable_cups(competition).each do |cup|
      headline.push(cup.competition_place)
    end

    config.show_columns_config.each do |col|
      headline.push(col[:name])
    end
    data = [headline]

    rows.each do |row|
      line = [row.rank, row.full_name]
      round.showable_cups(competition).each do |cup|
        participations = row.participations_for_cup(cup)
        if participations.present?
          d = participations.map do |participation|
            [participation.team_assessment.discipline.upcase, participation.result_entry_with_points]
          end
          my_table = pdf.make_table(d, cell_style: { size: 10, borders: [] })
          line.push(my_table)
        else
          line.push('')
        end
      end

      config.show_columns_config.each do |col|
        line.push(row.public_send(col[:method]))
      end

      data.push(line)
    end
    data
  end
end
