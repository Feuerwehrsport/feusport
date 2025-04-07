# frozen_string_literal: true

Recaptcha.configure do |config|
  config.site_key = ENV.fetch('HCAPTCHA_SITE_KEY', nil)
  config.secret_key = ENV.fetch('HCAPTCHA_SECRET_KEY', nil)
  config.api_server_url = 'https://hcaptcha.com/1/api.js'
  config.verify_url = 'https://hcaptcha.com/siteverify'
end
