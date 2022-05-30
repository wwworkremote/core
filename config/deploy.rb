# frozen_string_literal: true

lock '~> 3.17.0'

set :application, 'core'
set :repo_url, 'git@github.com:wwworkremote/core.git'
set :asdf_tools, %w[ruby]
set :branch, 'main'
set :deploy_to, '/home/deploy/projects/wwworkremote/core'

set :conditionally_migrate, true
set :migration_role, :app

set :whenever_roles, :cron

set :pty, true
set :ssh_options, { forward_agent: true }

append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'
# append :linked_files, 'config/database.yml', 'config/puma.rb', 'config/master.key', 'config/credentials/production.key'

# namespace :deploy do
#   namespace :sidekiq do
#     desc 'Stop Sidekiq'
#     task :stop do
#       on roles(:sidekiq) do
#         execute :sudo, :systemctl, :stop, :sidekiq
#       end
#     end
#
#     desc 'Start Sidekiq'
#     task :start do
#       on roles(:sidekiq) do
#         execute :sudo, :systemctl, :start, :sidekiq
#       end
#     end
#
#     desc 'Restart Sidekiq'
#     task :restart do
#       on roles(:sidekiq) do
#         execute :sudo, :systemctl, :restart, :sidekiq
#       end
#     end
#   end
# end

# after 'deploy:published', 'deploy:sidekiq:restart'
