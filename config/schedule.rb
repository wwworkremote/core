# frozen_string_literal: true

require 'whenever'

env :PATH, ENV.fetch('PATH', nil)

# set :job_template, "/usr/bin/env bash -l -c ':job' "
set :job_template, nil
set :output, '/home/deploy/projects/wwworkremote/core/shared/log/cron_production.log'

JOB_PREFIX = ' cd :path && :environment_variable=:environment nice -n 20 '

job_type :command, " #{JOB_PREFIX} :task :output "
job_type :rails, " #{JOB_PREFIX} bundle exec rails :task --silent :output "
job_type :runner, " #{JOB_PREFIX} bundle exec rails runner :task :output "
job_type :script, " #{JOB_PREFIX} bundle exec bin/:task :output "

every(5.minutes) { runner('HeartbeatWorker.perform_async') }
