# frozen_string_literal: true

# Findet Teilnehmer, zwischen deren Starts am Ende einer Startliste und am Anfang einer anderen
# Startliste desselben Tages weniger als RUNS Läufe liegen (z. B. letzter Lauf und dann Lauf 3:
# 0 + 2 = 2 Läufe dazwischen). Verglichen werden nur gleiche Personen bzw. Mannschaften (Staffeln zählen
# als ihre Mannschaft), nicht eine Person mit ihrer Mannschaft. Ohne Datum gilt eine Liste als
# »jeder Tag«. Sind beide Startzeiten bekannt, wird nur die passende Richtung geprüft.
class Score::ListGapCheck
  RUNS = 3

  # at_end: Der Teilnehmer steht in other_list am Ende (other_list läuft vorher), sonst am Anfang
  Conflict = Data.define(:entry, :other_list, :other_run, :at_end)

  attr_reader :list

  def initialize(list)
    @list = list
  end

  def conflicts
    @conflicts ||= other_lists.flat_map { |other| conflicts_with(other) }
  end

  def valid?
    conflicts.empty?
  end

  private

  def conflicts_with(other)
    other_rows = rows_by_list.fetch(other.id, [])
    return [] if other_rows.empty?

    other_max_run = other_rows.map(&:second).max
    entries.flat_map do |entry|
      key = key_for(entry.entity_type, entry.entity_id)
      other_rows.select { |row_key, _run| row_key == key }.filter_map do |_key, other_run|
        if other_first?(other) && runs_between(other_run, other_max_run, entry.run) < RUNS
          Conflict.new(entry:, other_list: other, other_run:, at_end: true)
        elsif other_later?(other) && runs_between(entry.run, max_run, other_run) < RUNS
          Conflict.new(entry:, other_list: other, other_run:, at_end: false)
        end
      end
    end
  end

  # Läufe nach dem Start in der früheren Liste plus Läufe vor dem Start in der späteren Liste
  def runs_between(earlier_run, earlier_max_run, later_run)
    (earlier_max_run - earlier_run) + (later_run - 1)
  end

  def other_first?(other)
    list.starting_time.nil? || other.starting_time.nil? || other.starting_time <= list.starting_time
  end

  def other_later?(other)
    list.starting_time.nil? || other.starting_time.nil? || other.starting_time >= list.starting_time
  end

  def other_lists
    @other_lists ||= begin
      lists = list.competition.score_lists.where.not(id: list.id)
      lists = lists.where(date: [list.date, nil]) if list.date.present?
      lists.to_a
    end
  end

  # Einträge dieser Liste aus dem Speicher, damit auch ungespeicherte Reihenfolgen (move) geprüft werden
  def entries
    @entries ||= list.entries.to_a
  end

  def max_run
    @max_run ||= entries.map(&:run).max
  end

  # { list_id => [[[entity_type, entity_id], run], ...] }
  def rows_by_list
    @rows_by_list ||= begin
      rows = Score::ListEntry.unscoped.where(list_id: other_lists.map(&:id))
                             .pluck(:list_id, :entity_type, :entity_id, :run)
      rows.group_by(&:first).transform_values do |list_rows|
        list_rows.map { |_list_id, type, id, run| [key_for(type, id), run] }
      end
    end
  end

  def key_for(entity_type, entity_id)
    return ['Team', relay_team_ids[entity_id]] if entity_type == 'TeamRelay'

    [entity_type, entity_id]
  end

  def relay_team_ids
    @relay_team_ids ||= TeamRelay.joins(:team).where(teams: { competition_id: list.competition_id })
                                 .pluck(:id, :team_id).to_h
  end
end
