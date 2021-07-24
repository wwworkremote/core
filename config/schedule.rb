# frozen_string_literal: true

TASKS = %w[
  ./exe/hackernews
  ./exe/indeed
  ./exe/indeed\ "javascript"
  ./exe/indeed\ "linux"
  ./exe/indeed\ "postgresql"
  ./exe/indeed\ "python"
  ./exe/indeed\ "rails"
  ./exe/indeed\ "redis"
  ./exe/indeed\ "ruby"
  ./exe/indeed\ "sidekiq"
  ./exe/monster
  ./exe/monster\ "javascript"
  ./exe/monster\ "linux"
  ./exe/monster\ "postgresql"
  ./exe/monster\ "python"
  ./exe/monster\ "rails"
  ./exe/monster\ "redis"
  ./exe/monster\ "ruby"
  ./exe/monster\ "sidekiq"
  ./exe/nexxt
  ./exe/nexxt\ "javascript"
  ./exe/nexxt\ "linux"
  ./exe/nexxt\ "postgresql"
  ./exe/nexxt\ "python"
  ./exe/nexxt\ "rails"
  ./exe/nexxt\ "redis"
  ./exe/nexxt\ "ruby"
  ./exe/nexxt\ "shell"
  ./exe/nexxt\ "sidekiq"
  ./exe/remoteok
  ./exe/remotepython
  ./exe/stackoverflow
  ./exe/stackoverflow\ "javascript"
  ./exe/stackoverflow\ "linux"
  ./exe/stackoverflow\ "postgresql"
  ./exe/stackoverflow\ "python"
  ./exe/stackoverflow\ "rails"
  ./exe/stackoverflow\ "redis"
  ./exe/stackoverflow\ "ruby"
  ./exe/stackoverflow\ "shell"
  ./exe/stackoverflow\ "sidekiq"
  ./exe/weworkremotely
].uniq.shuffle.freeze

require 'whenever'

env 'MAILTO', 'mike@just3ws.com'

set :job_template, "/usr/bin/env bash -l -c ':job' "
set :output, '/home/ubuntu/outlier_jobs/shared/log/cron_production.log'

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

every('3,33 * * * *', roles: [:cron1]) { runner './exe/messages' }
every('18,48 * * * *', roles: [:cron2]) { runner './exe/messages' }

every('7,37 * * * *', roles: [:cron1]) { runner './exe/moment' }
every('22,57 * * * *', roles: [:cron2]) { runner './exe/moment' }

every('8 * * * *', roles: [:cron1]) { runner './exe/tags' }
every('38 * * * *', roles: [:cron2]) { runner './exe/tags' }

scheduler(
  start_at: Date.today.to_datetime.to_time.utc,
  slots: planner(slots: TASKS.shuffle.freeze, duration: 1.day)
)

every(1.day, roles: [:cron1]) { rake 'pghero:capture_space_stats' }
every(9.minutes, roles: [:cron2]) { rake 'pghero:capture_query_stats' }
