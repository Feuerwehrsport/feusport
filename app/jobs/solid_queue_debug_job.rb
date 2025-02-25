# frozen_string_literal: true

class SolidQueueDebugJob < ApplicationJob
  def perform
    failed_jobs = SolidQueue::FailedExecution.all
    return if failed_jobs.blank?

    failed_ids = failed_jobs.map(&:id).sort.to_json
    current_file = Rails.root.join("tmp/failed_jobs-#{Date.current}.json")

    return if current_file.file? && current_file.read == failed_ids

    current_file.write(failed_ids)

    send_message(
      "#{failed_jobs.count} delayed jobs failed on #{`hostname`}",
      Rails.configuration.debug_email_address,
      failed_jobs.map { |job| JSON.pretty_generate(job.error) }.join("\n\n--NEXT--\n\n"),
    )
  end

  def send_message(subject, recipient, message)
    IO.popen("/usr/bin/mail -s #{Shellwords.escape(subject)} #{Shellwords.escape(recipient)}", 'w') do |mail|
      mail.puts(message)
    end
  end
end
