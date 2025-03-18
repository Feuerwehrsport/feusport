# frozen_string_literal: true

class ScoreListChannel < ApplicationCable::Channel
  def subscribed
    stream_from "score_list_#{params[:score_list_id]}_editable_#{params[:editable]}"
  end

  class Updater < ApplicationJob
    include Exports::ScoreLists

    def perform(list, run:, action: :update)
      tracks = {}
      tracks_editable = {}
      if action == :update
        score_list_entries(list) do |entry, crun, track, best_of_run|
          next if run != crun

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

      ActionCable.server.broadcast("score_list_#{list.id}_editable_false", { action:, run:, tracks: tracks })
      ActionCable.server.broadcast("score_list_#{list.id}_editable_true", { action:, run:, tracks: tracks_editable })
    end
  end
end
