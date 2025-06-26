# frozen_string_literal: true

module Exports::CompetitionResults
  def competition
    results.first.competition
  end

  def table_data(competition_result)
    header = %w[Platz Mannschaft]
    competition_result.results.each do |result|
      header.push(result.assessment.discipline.short_name)
      header.push('')
    end
    header.push('Punkte')
    rows = [header]

    all_rows = competition_result.rows
    all_rows.each do |row|
      current = [
        "#{competition_result.place_for_row(row)}.",
        row.team.full_name,
      ]
      competition_result.results.each do |result|
        assessment_result = row.assessment_result_from(result)
        current.push(assessment_result&.result_entry&.human_time)
        current.push(assessment_result&.points.to_s)
      end
      current.push(row.points.to_s)
      rows.push(current)
    end
    rows
  end

  def export_title
    parts = ['Gesamtwertung']
    parts.push(results.first.name) if results.one?
    parts.join(' - ')
  end
end
