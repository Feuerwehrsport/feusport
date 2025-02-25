# frozen_string_literal: true

class DebugJob < ApplicationJob
  def perform
    perform_log_parser
    perform_failed_solid_queue_jobs
  end

  private

  def perform_log_parser
    parser = RailsLogParser::Parser.from_file(RailsLogParser::Parser.log_path)

    message = parser.summary(last_minutes: 22)

    return if message&.strip.blank?

    send_message(
      "Interesting log lines on #{`hostname`}",
      message,
    )
  end

  def perform_failed_solid_queue_jobs
    failed_jobs = SolidQueue::FailedExecution.all
    return if failed_jobs.blank?

    failed_ids = failed_jobs.map(&:id).sort.to_json
    current_file = Rails.root.join("tmp/failed_jobs-#{Date.current}.json")

    return if current_file.file? && current_file.read == failed_ids

    current_file.write(failed_ids)

    send_message(
      "#{failed_jobs.count} delayed jobs failed on #{`hostname`}",
      failed_jobs.map { |job| JSON.pretty_generate(job.error) }.join("\n\n--NEXT--\n\n"),
    )
  end

  def send_message(subject, message)
    IO.popen(
      "/usr/bin/mail -s #{Shellwords.escape(subject)} #{Shellwords.escape(Rails.configuration.debug_email_address)}",
      'w',
    ) { |mail| mail.puts(message) }
  end
end
