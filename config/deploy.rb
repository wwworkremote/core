# frozen_string_literal: true

lock '~> 3.16.0'

set :application, 'wwworkremote'
set :repo_url, 'git@github.com:wwworkremote/core'
set :asdf_tools, %w[python ruby nodejs yarn]
set :branch, 'main'
set :deploy_to, '/home/deploy/projects/wwworkremote/core'

set :conditionally_migrate, true
set :migration_role, :app

set :whenever_roles, %i[cron1 cron2 cron3]

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, 'config/database.yml', 'config/puma.rb', 'config/master.key', 'config/credentials.yml.enc'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
