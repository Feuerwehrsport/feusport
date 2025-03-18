# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Feusport
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    config.generators.orm :active_record, primary_key_type: :uuid
    config.time_zone = 'Berlin'
    config.i18n.default_locale = :de

    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.preserve_finished_jobs = false

    config.generators.system_tests = nil
    config.generators.helper = false
    config.generators.assets = false
    config.generators.test_framework :rspec,
                                     controller_specs: false,
                                     fixtures: false,
                                     routing_specs: false,
                                     view_specs: false

    config.active_record.belongs_to_required_by_default = false
    config.active_record.encryption.key_derivation_salt =
      ENV.fetch('ENCRYPTION_KEY_DERIVATION_SALT', 'Oe0dCt3pLslia4nLkADHWmskBTfSRwb6')
    config.active_record.encryption.primary_key =
      ENV.fetch('ENCRYPTION_PRIMARY_KEY', 'S0KXvOn2ar5TOKTBv7KBxqwguYgaIdUO')

    config.x.email_validation = { mx: true }

    config.default_url_options = {}

    config.action_mailer.default_options = {
      from: 'Feuerwehrsport <no-reply@feusport.de>',
    }

    config.debug_email_address = 'georf@georf.de'
  end
end
