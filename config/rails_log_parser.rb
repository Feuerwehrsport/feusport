# frozen_string_literal: true

RailsLogParser.configure do |parser|
  parser.ignore_lines = [
    /SolidQueue.* Fail claimed jobs .* job_ids: \[\], process_ids: \[\]/,
    /WebSocket error occurred: Broken pipe/,
    /Ignoring message processed after the WebSocket was closed/,
  ]
end
