# frozen_string_literal: true

module Exports::ScoreResults
  extend ActiveSupport::Concern

  included do
    delegate :competition, to: :result
  end

  def build_data_rows(result, shortcut, export_headers: false, pdf: false, full: false)
    data = [build_data_headline(result, export_headers:, pdf:, full:)]
    result.rows.each do |row|
      entity = row&.entity

      line = []
      line.push "#{row.place}."
      if result.single_discipline?
        line.push(entity&.first_name, entity&.last_name)
        line.push(entity&.fire_sport_statistics_person_id) if full
        if shortcut
          line.push(entity&.team_shortcut_name(row&.assessment_type))
        else
          line.push(entity&.team_name(row&.assessment_type))
        end
        line.push(entity&.team&.fire_sport_statistics_team_id, entity&.team&.number, entity&.export_gender) if full
      else
        line.push(entity&.full_name)
        line.push(entity&.fire_sport_statistics_team_id, entity&.number, entity&.export_gender) if full
      end
      if result.multi_result_method_disabled?
        result.lists.each do |list|
          entry = row.result_entry_from(list)
          line.push(entry&.target_times_as_data(pdf:)) if pdf && list.separate_target_times?
          line.push(entry&.human_time.to_s)
        end
        line.push(row.best_result_entry&.human_time) unless result.lists.one?
      else
        result.results.each { |inner_result| line.push(row.result_entry_from(inner_result)&.human_time) }
        line.push(row.best_result_entry&.human_time)
      end
      data.push(line)
    end
    data
  end

  def build_data_headline(result, export_headers: false, pdf: false, full: false)
    header = ['Platz']
    if result.single_discipline?
      header.push('Vorname', 'Nachname')
      header.push('statistik_person_id') if full
    end
    header.push('Mannschaft')
    header.push('statistik_team_id', 'statistik_team_number', 'gender') if full
    if result.multi_result_method_disabled?
      result.lists.each do |list|
        if pdf && list.separate_target_times?
          header.push(content: list.shortcut, colspan: 2)
        else
          header.push(export_headers ? 'time' : list.shortcut)
        end
      end
      header.push('Bestzeit') unless result.lists.one?
    else
      result.results.each do |sub_result|
        header.push(sub_result.assessment.discipline.short_name)
      end
      header.push('Ergebnis')
    end
    header
  end

  def build_group_data_rows(result, full: false)
    header = %w[Platz Name Summe]
    header.push('statistik_team_id', 'statistik_team_number', 'gender') if full
    data = [header]

    result.group_result.rows.each do |row|
      line = ["#{row.place}.", row.team.full_name, row.result_entry.human_time]
      line.push(row&.team&.fire_sport_statistics_team_id, row&.team&.number, row&.team&.export_gender) if full
      data.push(line)
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
