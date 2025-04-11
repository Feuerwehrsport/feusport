# frozen_string_literal: true

class ScoreResultChannel < ApplicationCable::Channel
  def subscribed
    stream_from "score_result_#{params[:score_result_id]}"
  end

  class Updater < ApplicationJob
    include Exports::ScoreLists

    discard_on ActiveJob::DeserializationError

    def perform(result)
      html = ApplicationController.render(partial: 'competitions/score/results/result_show',
                                          locals: { result: result })

      ActionCable.server.broadcast("score_result_#{result.id}",
                                   { html: })
    end

    def self.safe_perform_later(result)
      updater = ScoreResultChannel::Updater.set(wait: 0.5.seconds).perform_later(result)

      my_job = SolidQueue::Job.find_by(active_job_id: updater.job_id)
      future_jobs = SolidQueue::Job.where(class_name: 'ScoreResultChannel::Updater', finished_at: nil)
                                   .where.not(active_job_id: updater.job_id)

      future_jobs.select { |fj| fj.arguments['arguments'] == my_job.arguments['arguments'] }.each(&:discard)
    end
  end
end
