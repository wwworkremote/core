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
set :output, '/home/deploy/projects/wwworkremote/core/shared/log/cron_production.log'

JOB_PREFIX = ' cd :path && :environment_variable=:environment nice -n 20 '

job_type :rails, " #{JOB_PREFIX} bundle exec rails :task --silent :output "
job_type :script, " #{JOB_PREFIX} bundle exec bin/:task :output "
job_type :runner, " #{JOB_PREFIX} bin/rails runner :task :output "
job_type :command, " #{JOB_PREFIX} :task :output "

def planner(slots:, duration:)
  count_from = ((duration.to_f / slots.count) / 2).to_i
  count_by = duration.to_f / (slots.count + 1)

  count_from.step(duration, count_by).map(&:to_i).zip(slots)
end

CRONS = %i[cron1 cron2 cron3].freeze

def scheduler(start_at:, slots:)
  i = 0
  slots.each do |slot|
    time = start_at + slot.first

    cron = "#{time.min} #{time.hour} * * *"
    task = slot.last

    next if task.to_s.strip.empty?

    i += 1
    i = 0 if i > 2

    host = CRONS[i]

    every(cron, roles: [host]) { runner task.to_s.strip }
  end
end

every('10 0,3,6,9,12,15,18,21 * * *', roles: [:cron1]) { runner './exe/job_postings' }
every('10 1,4,7,10,13,16,19,22 * * *', roles: [:cron2]) { runner './exe/job_postings' }
every('10 2,5,8,11,14,17,20,23 * * *', roles: [:cron3]) { runner './exe/job_postings' }

scheduler(
  start_at: Date.today.to_datetime.to_time.utc,
  slots: planner(slots: TASKS.shuffle, duration: 1.day)
)

every('10 2,5,8,11,14,17,20,23 * * *', roles: [:cron1]) { runner 'exe/job_posting_body_domains' }
every('25 2,5,8,11,14,17,20,23 * * *', roles: [:cron2]) { runner 'exe/source_domains' }
every('5 2,5,8,11,14,17,20,23 * * *',  roles: [:cron3]) { runner 'exe/job_posting_body_emails' }
every('40 2,5,8,11,14,17,20,23 * * *', roles: [:cron3]) { runner 'exe/target_domains' }
every('55 2,5,8,11,14,17,20,23 * * *', roles: [:cron2]) { runner 'exe/domains' }
every('50 2,5,8,11,14,17,20,23 * * *', roles: [:cron1]) { runner 'exe/email_domains' }

every(8.hours, roles: [:cron1]) { rake 'pghero:capture_space_stats' }
every(15.minutes, roles: [:cron2]) { rake 'pghero:capture_query_stats' }
