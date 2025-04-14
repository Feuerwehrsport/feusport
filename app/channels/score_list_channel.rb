# frozen_string_literal: true

class ScoreListChannel < ApplicationCable::Channel
  def subscribed
    stream_from "score_list_#{params[:score_list_id]}_editable_#{params[:editable]}"
  end

  class Updater < ApplicationJob
    include Exports::ScoreLists

    discard_on ActiveJob::DeserializationError

    def perform(list, tab_session_id:, run: nil)
      tracks = {}
      tracks_editable = {}
      if run.present?
        score_list_entries(list) do |entry, crun, track, best_of_run|
          next if run != crun
          next if entry.nil?

          tracks[entry.id] = ApplicationController.render(
            partial: 'competitions/score/lists/list_entry_with_times',
            locals: { entry:, run:, track:, list:, best_of_run:, editable: false, destroy_index: nil },
          )

          tracks_editable[entry.id] = ApplicationController.render(
            partial: 'competitions/score/lists/list_entry_with_times',
            locals: { entry:, run:, track:, list:, best_of_run:, editable: true, destroy_index: nil },
          )
        end
      end

      ActionCable.server.broadcast("score_list_#{list.id}_editable_false",
                                   { run:, tab_session_id:, tracks: tracks })
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
  end
end
