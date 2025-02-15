# frozen_string_literal: true

module Exports::ScoreLists
  def show_export_data(list, more_columns: false, pdf: false, hint_size: 6,
                       show_bib_numbers: competition.show_bib_numbers?,
                       separate_target_times_as_columns: false)
    data = [show_export_header(list, more_columns:,
                                     show_bib_numbers:,
                                     separate_target_times_as_columns:)]

    score_list_entries(list) do |entry, run, track, _best_of_run|
      line = []
      line.push((track == 1 ? run : ''), track)
      if list.single_discipline?
        line.push(entry&.entity&.bib_number.to_s) if show_bib_numbers

        line.push(fit_in(entry&.entity&.last_name, pdf:))
        line.push(fit_in(entry&.entity&.first_name, pdf:))
        team_name = entry&.entity&.team_shortcut_name(entry&.assessment_type)
      else
        team_name = entry&.entity&.full_name
      end
      team_name = append_assessment(list, entry, team_name, pdf:, hint_size:)
      if pdf
        line.push(content: team_name, inline_format: true)
      else
        line.push(team_name)
      end

      if list.separate_target_times?
        if separate_target_times_as_columns
          line.push(entry&.second_time_left_target, entry&.second_time_right_target)
        else
          line.push(entry&.target_times_as_data(pdf:, hint_size:))
        end
      end
      line.push(entry.try(:human_time))
      line.push('', '') if more_columns
      data.push(line)
    end
    data
  end

  def fit_in(name, pdf:)
    return name unless pdf

    name = name.to_s
    return name if name.length < 16
    return { content: name, size: 9 } if name.length < 20
    return { content: name, size: 8 } if name.length < 24
    return { content: name, size: 7 } if name.length < 28
    return { content: name, size: 6 } if name.length < 32

    { content: name, size: 5 }
  end

  def show_export_header(list, more_columns:, show_bib_numbers:, separate_target_times_as_columns:)
    header = %w[Lauf Bahn]
    if list.single_discipline?
      header.push('Nr.') if show_bib_numbers
      header.push('Nachname', 'Vorname')
    end
    header.push('Mannschaft')
    if more_columns
      header.push('', '', '')
    else
      if list.separate_target_times?
        if separate_target_times_as_columns
          header.push('Links', 'Rechts')
        else
          header.push('Ziele')
        end
      end
      header.push('Zeit')
    end
    header
  end

  def score_list_entries(list, move_modus: false)
    entries = if list.errors.present?
                list.entries.to_a
              else
                list.entries.includes(:entity).to_a
              end
    entries.sort_by!(&:run_and_track_sortable)
    best_of_runs = list.show_best_of_run? ? calculate_best_of_runs(entries) : {}
    track = 0
    run = 1
    entry = entries.shift
    invalid_count = 0
    extra_run = move_modus
    while entry.present? || track != 0 || extra_run
      extra_run = false if entry.blank? && track.zero? && extra_run
      track += 1
      if entry && entry.track == track && entry.run == run
        yield entry, run, track, entry.in?(best_of_runs[run] || [])
        entry = entries.shift
      else
        yield nil, run, track, false
      end

      if track == list.track_count
        track = 0
        run += 1
      end

      invalid_count += 1
      return if invalid_count > 1000
    end
  end

  def calculate_best_of_runs(entries)
    entries.select(&:result_valid?).group_by(&:run).to_h do |run, runners|
      best_per_assessments = runners.group_by(&:assessment_id).map do |_, ass_runners|
        ass_runners.group_by(&:time).min.second
      end
      [run, best_per_assessments.inject(&:+)]
    end
  end

  def append_assessment(list, entry, team_name, pdf:, hint_size: 6)
    if list.show_multiple_assessments? && list.multiple_assessments? && entry.present?
      team_name += if pdf
                     "<font size='#{hint_size}'> (#{entry&.assessment&.name})</font>"
                   else
                     " (#{entry&.assessment&.name})"
                   end
    end
    team_name
  end

  def export_title
    list.name
  end
end
