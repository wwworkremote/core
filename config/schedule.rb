# frozen_string_literal: true

require 'whenever'

env 'MAILTO', 'mike@just3ws.com'

set :job_template, "/usr/bin/env bash -l -c ':job' "
set :output, '/home/ubuntu/outlier_jobs/shared/log/cron_production.log'

JOB_PREFIX = ' cd :path && :environment_variable=:environment nice -n 20 '

# job_type :exclusive_rails, " cd :path && flock -n 'tmp/pids/cron_:task.lock' -c ':environment_variable=:environment nice -n 20 bundle exec rails :task --silent --backtrace :output'"

job_type :rails,  " #{JOB_PREFIX} bundle exec rails :task --silent :output "
job_type :script, " #{JOB_PREFIX} bundle exec bin/:task :output "
job_type :runner, " #{JOB_PREFIX} bin/rails runner -e :environment ':task' :output "
job_type :command,  " #{JOB_PREFIX} :task :output "

every('0 0-7 * * *') { runner 'exe/stackoverflow' }
every('8 0-7 * * *') { runner 'exe/remotepython' }
every('16 0-7 * * *') { runner 'exe/nexxt' }
every('24 0-7 * * *') { runner 'exe/indeed' }
every('32 0-7 * * *') { runner 'exe/hackernews' }
every('40 0-7 * * *') { runner 'exe/remoteok' }
every('48 0-7 * * *') { runner 'exe/monster' }
every('56 0-7 * * *') { runner 'exe/weworkremotely' }

every :day, at: '8:08am', roles: [:cron] do # UTC
  command 'exe/dice'
end

every('0 9-23 * * *') { runner 'exe/stackoverflow' }
every('8 9-23 * * *') { runner 'exe/remotepython' }
every('16 9-23 * * *') { runner 'exe/nexxt' }
every('24 9-23 * * *') { runner 'exe/indeed' }
every('32 9-23 * * *') { runner 'exe/hackernews' }
every('40 9-23 * * *') { runner 'exe/remoteok' }
every('48 9-23 * * *') { runner 'exe/monster' }
every('56 9-23 * * *') { runner 'exe/weworkremotely' }
