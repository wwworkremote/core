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
