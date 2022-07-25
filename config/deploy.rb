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

# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'
# append :linked_files, 'config/database.yml', 'config/puma.rb', 'config/master.key', 'config/credentials/production.key'

append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'

# append :linked_files, 'config/database.yml', 'config/secrets.yml'

namespace :puma do
  desc 'Create directories for Puma PIDs and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/tmp/sockets"
      execute "mkdir -p #{shared_path}/tmp/pids"
    end
  end

  before 'deploy:starting', 'puma:make_dirs'
end

namespace :deploy do
  desc 'Ensure git is in sync with remote'
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/main`
        puts 'WARNING: HEAD is not the same as origin/main'
        puts 'Run `git push` to sync changes.'

        exit
      end
    end
  end
end

