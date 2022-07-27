# frozen_string_literal: true

require 'whenever'

env :PATH, ENV.fetch('PATH', nil)

set :job_template, "/usr/bin/env bash -l -c ':job' "
set :output, '/home/deploy/projects/wwworkremote/core/shared/log/cron_production.log'

JOB_PREFIX = ' cd :path && :environment_variable=:environment '

job_type :command, " #{JOB_PREFIX} :task :output "
job_type :rails, " #{JOB_PREFIX} sbin/rails :task --silent :output "
job_type :runner, " #{JOB_PREFIX} sbin/rails runner :task :output "
job_type :script, " #{JOB_PREFIX} bin/:task :output "

every(15.minutes) { runner('HeartbeatWorker.perform_async') }
