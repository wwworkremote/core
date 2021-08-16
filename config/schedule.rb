# frozen_string_literal: true

TASKS = %w[
  ./exe/hackernews
  ./exe/indeed
  ./exe/monster
  ./exe/nexxt
  ./exe/remoteok
  ./exe/remotepython
  ./exe/stackoverflow
  ./exe/weworkremotely
].freeze

require 'whenever'

env 'MAILTO', 'mike@just3ws.com'

set :job_template, "/usr/bin/env bash -l -c ':job' "
set :output, '/home/deploy/projects/outlier_jobs/core/shared/log/cron_production.log'

JOB_PREFIX = ' cd :path && :environment_variable=:environment nice -n 20 '

job_type :rails,  " #{JOB_PREFIX} bundle exec rails :task --silent :output "
job_type :script, " #{JOB_PREFIX} bundle exec bin/:task :output "
job_type :runner, " #{JOB_PREFIX} bin/rails runner :task :output "
job_type :command,  " #{JOB_PREFIX} :task :output "

def planner(slots:, duration:)
  count_from = ((duration.to_f / slots.count) / 2).to_i
  count_by = duration.to_f / (slots.count + 1)

  count_from.step(duration, count_by).map(&:to_i).zip(slots)
end

CRONS = %i[cron1 cron2].freeze

def scheduler(start_at:, slots:)
  slots.each_with_index do |slot, i|
    time = start_at + slot.first

    cron = "#{time.min} #{time.hour} * * *"
    task = slot.last

    next if task.to_s.strip.empty?

    host = CRONS[i.even? ? 0 : 1]

    every(cron, roles: [host]) { runner task.to_s.strip }
  end
end

# every('10 0,2,4,6,8,10,12,14,16,18,20,22 * * *', roles: [:cron1]) { runner './exe/job_postings' }
# every('10 1,3,5,7,9,11,13,15,17,19,21,23 * * *', roles: [:cron2]) { runner './exe/job_postings' }

# every('30 0,2,4,6,8,10,12,14,16,18,20,22 * * *', roles: [:cron1]) { runner './exe/moment' }
# every('30 1,3,5,7,9,11,13,15,17,19,21,23 * * *', roles: [:cron2]) { runner './exe/moment' }

# every('50 0,2,4,6,8,10,12,14,16,18,20,22 * * *', roles: [:cron1]) { runner './exe/tags' }
# every('50 1,3,5,7,9,11,13,15,17,19,21,23 * * *', roles: [:cron2]) { runner './exe/tags' }

scheduler(
  start_at: Date.today.to_datetime.to_time.utc,
  slots: planner(slots: TASKS.shuffle, duration: 1.day)
)

every(8.hours, roles: [:cron1]) { rake 'pghero:capture_space_stats' }
every(15.minutes, roles: [:cron2]) { rake 'pghero:capture_query_stats' }
