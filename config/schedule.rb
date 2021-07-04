# frozen_string_literal: true

require 'whenever'

env 'MAILTO', 'mike@just3ws.com'

set :job_template, "/usr/bin/env bash -l -c ':job'"
set :output, '/home/ubuntu/outlier_jobs/shared/log/cron_production.log'

JOB_PREFIX = ' cd :path && PATH=:env_path:"$PATH" :environment_variable=:environment nice -n 20 '

# job_type :exclusive_rails, " cd :path && flock -n 'tmp/pids/cron_:task.lock' -c 'PATH=:env_path:\"$PATH\" :environment_variable=:environment nice -n 20 bundle exec rails :task --silent --backtrace :output'"

job_type :rails,  " #{JOB_PREFIX} bundle exec rails :task --silent :output "
job_type :script, " #{JOB_PREFIX} bundle exec bin/:task :output "
job_type :runner, " #{JOB_PREFIX} bin/rails runner -e :environment ':task' :output "
job_type :command,  " #{JOB_PREFIX} :task :output "

every('0 * * * *') { runner 'exe/stackoverflow' }
every('8 * * * *') { runner 'exe/remotepython' }
every('16 * * * *') { runner 'exe/nexxt' }
every('24 * * * *') { runner 'exe/indeed' }
every('32 * * * *') { runner 'exe/hackernews' }
every('40 * * * *') { runner 'exe/remoteok' }
every('48 * * * *') { runner 'exe/monster' }
every('56 * * * *') { runner 'exe/weworkremotely' }

every :day, at: "6:#{rand(0..59)}am", roles: [:cron] do # UTC
  command 'exe/dice'
end
