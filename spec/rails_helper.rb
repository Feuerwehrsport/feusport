# frozen_string_literal: true

if ENV['CI_SERVER'].nil?
  require 'simplecov'
  SimpleCov.start 'rails'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'spec_views/support'
require 'devise'

ActiveRecord::Migration.maintain_test_schema!
Rails.root.glob('spec/support/**/*.rb').each { |f| require f }

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.use_transactional_fixtures = false

  config.before do
    FactoryBot.rewind_sequences
    ActiveJob::Base.queue_adapter.enqueue_after_transaction_commit = false
    view_sanitizer.gsub(/[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}/, 'UUID')
  end
  config.before(type: :mailer) do
    view_sanitizer.gsub(/src="cid:[^\s.]+.mail"/, 'src="cid:CID.mail"')
  end

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
