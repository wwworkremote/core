# frozen_string_literal: true

lock '~> 3.17.0'

set :application, 'core'
set :repo_url, 'git@github.com:wwworkremote/core.git'
set :asdf_tools, %w[ruby]
set :branch, 'main'
set :deploy_to, '/home/deploy/projects/wwworkremote/core'

set :whenever_roles, :cron

set :pty, true
set :ssh_options, { forward_agent: true }

# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'
LINKED_DIRS = %w[.bundle log public/system public/uploads tmp/cache tmp/pids tmp/sockets vendor/bundle].freeze
append(:linked_dirs, *LINKED_DIRS)

namespace :puma do
  desc 'Create directories for Puma PIDs and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/log"
      execute "mkdir -p #{shared_path}/pids"
      execute "mkdir -p #{shared_path}/services"
      execute "mkdir -p #{shared_path}/sockets"
      execute "mkdir -p #{shared_path}/tmp/pids"
      execute "mkdir -p #{shared_path}/tmp/sockets"
    end
  end

  before 'deploy:starting', 'puma:make_dirs'
end

namespace :deploy do
  namespace :sidekiq do
    desc 'Restart sidekiq service'
    task :restart do
      on roles(:app) do
        execute :sudo, :systemctl, :stop, :sidekiq
        execute :sudo, :systemctl, :restart, :sidekiq
      end
    end
  end

  namespace :nginx do
    desc 'Restart nginx'
    task :restart do
      on roles(:web) do
        execute :sudo, :systemctl, :stop, :nginx
        execute :sudo, :systemctl, :restart, :nginx
      end
    end
  end
end
