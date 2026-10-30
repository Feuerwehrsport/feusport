# frozen_string_literal: true

class ScoreListChannel < ApplicationCable::Channel
  # Bearbeitbarer Stream (Zeiten trotz hidden_results, Bearbeiten-Links) nur mit Bearbeitungsrecht,
  # versteckte Listen gar nicht für Besucher
  def subscribed
    list = Score::List.find_by(id: params[:score_list_id])
    return reject if list.nil?

    ability = ability_for(list.competition)
    editable = ActiveModel::Type::Boolean.new.cast(params[:editable]) == true
    allowed = editable ? ability.can?(:edit_times, list) : ability.can?(:read, list) && !list.hidden?
    return reject unless allowed

    stream_from "score_list_#{list.id}_editable_#{editable}"
  end

  class Updater < ApplicationJob
    include Exports::ScoreLists

    discard_on ActiveJob::DeserializationError

    # Berechtigungen gelten nur beim Abonnieren. Deshalb hier den aktuellen Stand prüfen: Wurde die Liste
    # (oder der Wettkampf) inzwischen versteckt, bekommen schon verbundene Besucher nichts mehr.
    def perform(list, tab_session_id:, run: nil)
      public = list.competition.visible? && !list.hidden?
      tracks = {}
      tracks_editable = {}
      if run.present?
        score_list_entries(list) do |entry, crun, track, best_of_run|
          next if run != crun
          next if entry.nil?

          locals = { entry:, run:, track:, list:, best_of_run: }
          tracks[entry.id] = render_entry(**locals, editable: false) if public
          tracks_editable[entry.id] = render_entry(**locals, editable: true)
        end
      end

      if public
        ActionCable.server.broadcast("score_list_#{list.id}_editable_false",
                                     { run:, tab_session_id:, tracks: tracks })
      end
      ActionCable.server.broadcast("score_list_#{list.id}_editable_true",
                                   { run:, tab_session_id:, tracks: tracks_editable })
    end

    def self.safe_perform_later(list, run: nil, tab_session_id: nil)
      updater = ScoreListChannel::Updater.set(wait: 0.5.seconds).perform_later(list, run:, tab_session_id:)

      arguments = SolidQueue::Job.find_by(active_job_id: updater.job_id)&.arguments&.[]('arguments')
      return if arguments.nil?

      future_jobs = SolidQueue::Job.where(class_name: 'ScoreListChannel::Updater', finished_at: nil)
                                   .where.not(active_job_id: updater.job_id)

      future_jobs.select { |fj| fj.arguments['arguments'] == arguments }.each(&:discard)
    end

    private

    def render_entry(**locals)
      ApplicationController.render(partial: 'competitions/score/lists/list_entry_with_times',
                                   locals: { **locals, destroy_index: nil, edit_index: nil })
    end
  end
end
