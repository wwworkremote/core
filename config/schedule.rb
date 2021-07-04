# frozen_string_literal: true

require 'whenever'

env 'MAILTO', 'mike@just3ws.com'

set :job_template, "/usr/bin/env bash -l -c ':job'"
set :output, '/home/ubuntu/outlier_jobs/shared/log/cron_production.log'

JOB_PREFIX = ' cd :path && PATH=:env_path:"$PATH" RAILS_ENV=:environment nice -n 20 '

job_type :exclusive_rails, " cd :path && flock -n 'tmp/pids/cron_:task.lock' -c 'PATH=:env_path:\"$PATH\" RAILS_ENV=:environment nice -n 20 bundle exec rails :task --silent --backtrace :output'"

job_type :rails,  " #{JOB_PREFIX} bundle exec rails :task --silent :output "
job_type :script, " #{JOB_PREFIX} bundle exec bin/:task :output "
job_type :runner, " #{JOB_PREFIX} bin/rails runner -e :environment ':task' :output "
job_type :shell,  " #{JOB_PREFIX} :task "

every(33.minutes) { runner 'exe/remotepython' }
every(34.minutes) { runner 'exe/nexxt' }
every(35.minutes) { runner 'exe/indeed' }
every(36.minutes) { runner 'exe/hackernews' }
every(37.minutes) { runner 'exe/remoteok' }
every(38.minutes) { runner 'exe/monster' }
every(39.minutes) { runner 'exe/weworkremotely' }

every(1.hour) { runner 'exe/stackoverflow' }

every :day, at: '1:20am', roles: [:cron] do
  shell 'exe/dice'
end
