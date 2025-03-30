# frozen_string_literal: true

SimpleCov.start do
  track_files '{app,lib}/**/*.rb'

  add_filter '/spec/'
  add_filter '/app/models/concerns/schema_validations.rb'
  add_filter '/app/jobs/debug_job.rb'
end

SimpleCov.at_exit do
  output = {
    covered_percent: SimpleCov.result.covered_percent,
    files: SimpleCov.result.files.count,
    total_lines: SimpleCov.result.total_lines,
    covered_lines: SimpleCov.result.covered_lines,
    missed_lines: SimpleCov.result.missed_lines,
  }
  Rails.root.join('doc/simplecov.json').write(JSON.pretty_generate(output))

  SimpleCov.result.format!
end
