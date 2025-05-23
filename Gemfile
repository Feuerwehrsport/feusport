# frozen_string_literal: true

source 'https://rubygems.org'
ruby '3.3.7'

gem 'rails', '~> 7.0'

gem 'pg' # database
gem 'puma' # webserver for development
gem 'bcrypt' # password hashing
gem 'redis' # Adapter for ActionCable

gem 'sprockets-rails' # asset pipeline
gem 'jsbundling-rails' # bundle and transpile JavaScript
gem 'cssbundling-rails' # bundle and process CSS
gem 'sassc-rails' # use Sass to process CSS
gem 'haml-rails' # haml as template engine
gem 'turbo-rails' # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'auto_strip_attributes' # remove whitespaces and change to nil

gem 'bootsnap', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'generated_schema_validations' # validate models by schema
gem 'rails_log_parser' # to analyise log

gem 'solid_queue' # background jobs

gem 'simple_form' # rails form helper
gem 'devise' # user authentication
gem 'active_link_to' # add class to link
gem 'acts_as_list' # position in lists
gem 'cancancan' # model authentication
gem 'redcarpet' # markdown to html parser
gem 'image_processing' # generate previews and thumbs
gem 'activestorage-validator' # validate stored files
gem 'valid_email2' # validates email addresses
gem 'recaptcha', require: 'recaptcha/rails' # captch for registration

# exports
gem 'caxlsx'
gem 'prawn'
gem 'prawn-table'
gem 'prawn-qrcode'
gem 'matrix'

gem 'concurrent-ruby', '1.3.4' # to hold an this gem in the old version, wait for fix (bad version is 1.3.5)

gem 'mutex_m' # remove on Rails 7.2
gem 'drb' # remove on Rails 7.2
gem 'base64' # remove on Rails 7.2

group :development, :test do
  gem 'debug' # debugger

  gem 'rspec-rails' # test framework
  gem 'spec_views' # compare html output
  gem 'factory_bot' # create db fixtures
  gem 'vcr' # record http requests
  gem 'webmock' # mock http requests
  gem 'annotate' # schema info in model

  # code beautifier
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'haml-lint', require: false
  gem 'i18n-tasks'

  gem 'guard', require: false # on demand tests
  gem 'guard-rspec', require: false # on demand tests

  gem 'simplecov', require: false # test coverage

  gem 'csv' # inspect spreadsheets
  gem 'roo' # inspect spreadsheets

  # audit tools
  gem 'bundler-audit'
  gem 'brakeman'
end

group :development do
  gem 'web-console' # Use console on exceptions pages

  gem 'capistrano-rsync-plugin', git: 'https://github.com/Lichtbit/capistrano-rsync-plugin' # speed up deploying
  gem 'm3_capistrano3', git: 'git@gitlab.lichtbit.com:lichtbit/m3_capistrano3.git' # deploying tool
end
