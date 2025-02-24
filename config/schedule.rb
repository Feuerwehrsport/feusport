# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.

def rails_command(command)
  command "/usr/local/bin/feusport.rails #{command} | break_long_lines"
end

if environment == 'production'
  every 20.minutes do
    #     rails_command 'debug:failed_delayed_jobs'
    rails_command 'rails_log_parser:parse[22]'
  end
end
