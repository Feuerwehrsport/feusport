# frozen_string_literal: true

module Exports::ScoreResults
  extend ActiveSupport::Concern
  included do
    delegate :competition, :discipline, to: :result
  end

  def build_data_rows(result, discipline, shortcut, export_headers: false, pdf: false)
    data = [build_data_headline(result, discipline, export_headers:, pdf:)]
    result.rows.each do |row|
      line = []
      line.push "#{result.place_for_row(row)}."
      if discipline.single_discipline?
        line.push(row&.entity&.first_name, row&.entity&.last_name)
        if shortcut
          line.push(row&.entity&.team_shortcut_name(row&.assessment_type))
        else
          line.push(row&.entity&.team_name(row&.assessment_type))
        end
      else
        line.push(row&.entity&.full_name)
      end
      if row.is_a? Score::DoubleEventResultRow
        result.results.each { |inner_result| line.push(row.result_entry_from(inner_result).to_s) }
        line.push(row.sum_result_entry.to_s)
      else
        result.lists.each do |list|
          entry = row.result_entry_from(list)
          line.push(entry&.target_times_as_data(pdf:)) if pdf && list.separate_target_times?
          line.push(entry&.human_time.to_s)
        end
        line.push(row.best_result_entry&.human_time) unless result.lists.count == 1
      end
      data.push(line)
    end
    data
  end

  def build_data_headline(result, discipline, export_headers: false, pdf: false)
    header = ['Platz']
    if discipline.single_discipline?
      header.push('Vorname', 'Nachname', 'Mannschaft')
    else
      header.push('Mannschaft')
    end
    if result.calculation_method_zweikampf?
      result.results.each do |sub_result|
        header.push(sub_result.assessment.discipline.short_name)
      end
      header.push('Summe')
    else
      result.lists.each do |list|
        if pdf && list.separate_target_times?
          header.push(content: list.shortcut, colspan: 2)
        else
          header.push(export_headers ? 'time' : list.shortcut)
        end
      end
      header.push('Bestzeit') unless result.lists.count == 1
    end
    header
  end

  def build_group_data_rows(result)
    data = [%w[Platz Name Summe]]
    result.group_result.rows.each do |row|
      data.push ["#{result.group_result.place_for_row(row)}.", row.team.full_name, row.result_entry.human_time]
    end
    data
  end

  GroupDetails = Struct.new(:team, :result_entry, :rows_in, :rows_out)

  def build_group_data_details_rows(result)
    result.group_result.rows.map do |row|
      rows_in = row.rows_in.map { |r| [r.entity.full_name, r.best_result_entry.human_time] }
      rows_out = row.rows_out.map { |r| [r.entity.full_name, r.best_result_entry.human_time] }
      GroupDetails.new(row.team, row.result_entry, rows_in, rows_out)
    end
  end

  def export_title
    result.name
  end
end
