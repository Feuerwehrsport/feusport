# frozen_string_literal: true

class ScoreResultChannel < ApplicationCable::Channel
  # Admins bekommen einen eigenen Stream, der nicht öffentliche Startlisten enthält (Score::Result#include_hidden_lists)
  def subscribed
    result = Score::Result.find_by(id: params[:score_result_id])
    return reject if result.nil?

    ability = ability_for(result.competition)
    return reject unless ability.can?(:read, result)

    stream_from self.class.stream_name(result, admin: ability.can?(:manage, result.competition))
  end

  def self.stream_name(result, admin:)
    "score_result_#{result.id}#{'_admin' if admin}"
  end

  class Updater < ApplicationJob
    include Exports::ScoreLists

    discard_on ActiveJob::DeserializationError

    # Wie bei ScoreListChannel::Updater: ist der Wettkampf inzwischen unsichtbar, nichts mehr an Besucher senden
    def perform(result)
      broadcast(result, admin: false) if result.competition.visible?

      admin_result = Score::Result.find(result.id)
      admin_result.include_hidden_lists = true
      broadcast(admin_result, admin: true)
    end

    def self.safe_perform_later(result)
      updater = ScoreResultChannel::Updater.set(wait: 0.5.seconds).perform_later(result)

      arguments = SolidQueue::Job.find_by(active_job_id: updater.job_id)&.arguments&.[]('arguments')
      return if arguments.nil?

      future_jobs = SolidQueue::Job.where(class_name: 'ScoreResultChannel::Updater', finished_at: nil)
                                   .where.not(active_job_id: updater.job_id)

      future_jobs.select { |fj| fj.arguments['arguments'] == arguments }.each(&:discard)
    end

    private

    def broadcast(result, admin:)
      html = ApplicationController.render(partial: 'competitions/score/results/result_show', locals: { result: })
      ActionCable.server.broadcast(ScoreResultChannel.stream_name(result, admin:), { html: })
    end
  end
end
