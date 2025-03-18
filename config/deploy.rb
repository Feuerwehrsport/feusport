# frozen_string_literal: true

# config valid for current version and patch releases of Capistrano
lock '~> 3.17'

set :application, 'feusport'
set :repo_url, 'git@github.com:Feuerwehrsport/feusport.git'
set :deploy_to, '/srv/feusport'

set :branch, 'main'

set :rvm_ruby_version, '3.3.7'
set :migration_servers, -> { release_roles(fetch(:migration_role)) }

set :enable_solid_queue, true
set :enable_puma, true

namespace :feusport do
  desc 'generate static error pages'
  task :generate_static_html do
    on roles(:web) do |_host|
      within release_path do
        execute :curl,
                '-sk', 'https://feusport.de/not_found', '-o', 'public/404.html'
        execute :curl,
                '-sk', 'https://feusport.de/unprocessable_entity', '-o', 'public/422.html'
        execute :curl,
                '-sk', 'https://feusport.de/internal_server_error', '-o', 'public/500.html'
      end
    end
  end
end

after 'm3:puma_reload', 'feusport:generate_static_html'
