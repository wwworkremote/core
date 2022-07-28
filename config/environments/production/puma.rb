#!/usr/bin/env puma
# frozen_string_literal: true

environment 'production'

app_dir = '/home/deploy/projects/wwworkremote/core/current'
shared_dir = '/home/deploy/projects/wwworkremote/core/shared'

bind "unix://#{shared_dir}/sockets/puma.sock"
pidfile "#{shared_dir}/pids/puma.pid"
state_path "#{shared_dir}/pids/puma.state"
directory "#{app_dir}/"

stdout_redirect "#{shared_dir}/log/puma.access.log", "#{shared_dir}/log/puma.error.log", true

workers 0
threads 0, 16

activate_control_app "unix://#{app_dir}/pumactl.sock"

prune_bundler
