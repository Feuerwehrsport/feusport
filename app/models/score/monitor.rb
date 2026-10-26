# frozen_string_literal: true

# Live-Anzeige für Monitore: pro Startliste die letzten Ergebnisse, den aktuellen Lauf und die nächsten Läufe.
# Zeigt immer die öffentliche Sicht (keine versteckten Listen, keine versteckten Zeiten), auch für Admins.
class Score::Monitor
  PREVIOUS_RUNS = 2
  VISIBLE_RUNS = 12

  # entries: ein Eintrag (oder nil) pro Bahn, state: :done, :current oder :upcoming
  Run = Data.define(:number, :entries, :state)
  Block = Data.define(:list, :runs, :following_list, :following_runs)

  attr_reader :competition

  def initialize(competition, list_ids: nil)
    @competition = competition
    @list_ids = Array(list_ids).map(&:to_s).compact_blank
  end

  def automatic?
    @list_ids.empty?
  end

  def available_lists
    @available_lists ||= competition.score_lists.where(hidden: false).to_a
  end

  def lists
    @lists ||= automatic? ? automatic_lists : available_lists.select { |list| list.id.in?(@list_ids) }
  end

  def blocks
    @blocks ||= begin
      following_shown = false
      lists.map do |list|
        runs = visible_runs(runs_of(list))
        open_runs = runs.count { |run| run.state != :done }
        following_list = following_list_candidate if !following_shown && open_runs < VISIBLE_RUNS
        following_shown ||= following_list.present?
        following_runs = following_list ? runs_of(following_list).first(VISIBLE_RUNS - open_runs) : []
        Block.new(list:, runs:, following_list:, following_runs:)
      end
    end
  end

  private

  # Laufende Listen, sonst die erste noch nicht begonnene, sonst die zuletzt geänderte beendete
  def automatic_lists
    running = lists_with_status(:running)
    return running if running.any?

    pending = lists_with_status(:pending)
    return pending.first(1) if pending.any?

    lists_with_status(:finished).max_by(&:updated_at).then { |list| list ? [list] : [] }
  end

  # Nur wenn genau eine weitere Liste noch nicht begonnen hat, ist klar, welche als Nächstes kommt
  def following_list_candidate
    candidates = lists_with_status(:pending) - lists
    candidates.first if candidates.one?
  end

  def lists_with_status(status)
    available_lists.select { |list| list_status(list) == status }
  end

  def list_status(list)
    waiting = entry_counts[[list.id, 'waiting']] || 0
    total = entry_counts.select { |(list_id, _), _| list_id == list.id }.values.sum
    if total.zero? then :empty
    elsif waiting == total then :pending
    elsif waiting.zero? then :finished
    else
      :running
    end
  end

  def entry_counts
    @entry_counts ||= Score::ListEntry.where(list_id: available_lists.map(&:id))
                                      .reorder(nil).group(:list_id, :result_type).count
  end

  # Fokus ist der Lauf nach dem letzten Lauf mit Ergebnis, ausgelassene Läufe davor zählen nicht.
  # Ohne Ergebnisse beginnt die Liste oben.
  def visible_runs(runs)
    last_index = runs.rindex { |run| result?(run) } || -1
    done = runs[..last_index].select { |run| result?(run) }.last(PREVIOUS_RUNS)
    upcoming = runs[(last_index + 1)..].first(VISIBLE_RUNS)
    done.map { |run| run.with(state: :done) } +
      upcoming.each_with_index.map { |run, index| run.with(state: index.zero? ? :current : :upcoming) }
  end

  def result?(run)
    run.entries.compact.any? { |entry| !entry.result_waiting? }
  end

  def runs_of(list)
    entries = list.entries.includes(:entity, :assessment).to_a
    entries.group_by(&:run).sort.map do |number, run_entries|
      tracks = Array.new(list.track_count)
      run_entries.each { |entry| tracks[entry.track - 1] = entry if entry.track.between?(1, list.track_count) }
      Run.new(number:, entries: tracks, state: :upcoming)
    end
  end
end
