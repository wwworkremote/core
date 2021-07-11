# frozen_string_literal: true

TERMS = %w[
  ansible
  api
  bash
  capistrano
  css
  devops
  git
  github
  gitlab
  golang
  java
  javascript
  jquery
  json
  jsonapi
  kafka
  middleware
  mysql
  nodejs
  postgres
  postgresql
  puma
  python
  rails
  redis
  rspec
  ruby
  sass
  sidekiq
  sql
  vim
  zsh
].freeze

TASKS_WITH_TERMS = %w[monster stackoverflow].flat_map { |task| TERMS.flat_map { |term| "#{task} #{term}" } }.freeze

TASKS = %w[
  hackernews
  indeed
  nexxt
  remoteok
  remotepython
  weworkremotely
].concat(TASKS_WITH_TERMS).freeze

require 'whenever'

env 'MAILTO', 'mike@just3ws.com'

set :job_template, "/usr/bin/env bash -l -c ':job' "
set :output, '/home/ubuntu/outlier_jobs/shared/log/cron_production.log'

JOB_PREFIX = ' cd :path && :environment_variable=:environment nice -n 20 '

# job_type :exclusive_rails, " cd :path && flock -n 'tmp/pids/cron_:task.lock' -c ':environment_variable=:environment nice -n 20 bundle exec rails :task --silent --backtrace :output'"

job_type :rails,  " #{JOB_PREFIX} bundle exec rails :task --silent :output "
job_type :script, " #{JOB_PREFIX} bundle exec bin/:task :output "
job_type :runner, " #{JOB_PREFIX} bin/rails runner -e :environment :task :output "
job_type :command,  " #{JOB_PREFIX} :task :output "

def planner(slots:, duration:)
  count_from = ((duration.to_f / slots.count) / 2).to_i
  count_by = duration.to_f / (slots.count + 1)

  count_from.step(duration, count_by).map(&:to_i).zip(slots)
end

def scheduler(start_at:, slots:)
  hosts = %i[cron1 cron2].freeze

  slots.each_with_index do |slot, i|
    time = start_at + slot.first

    cron = "#{time.min} #{time.hour} * * *"
    task = slot.last

    next if task.to_s.strip.empty?

    host = hosts[i.even? ? 0 : 1]

    every(cron, roles: [host]) { runner "exe/#{task}" }
  end
end

# every 30 minutes on the quarter hour alternate hosts
every('15 * * * *', roles: [:malina101]) { runner 'exe/messages' }
every('45 * * * *', roles: [:malina102]) { runner 'exe/messages' }

# every 30 minutes on the twenty alternate hosts
every('50 * * * *', roles: [:malina101]) { runner 'exe/messages' }
every('20 * * * *', roles: [:malina102]) { runner 'exe/messages' }

scheduler(
  start_at: Date.today.to_datetime.to_time.utc,
  slots: planner(slots: TASKS.shuffle, duration: 7.hours)
)

every :day, at: '8:08am', roles: [:cron] do # UTC
  command 'exe/dice'
end

scheduler(
  start_at: Date.today.to_datetime.to_time.utc + 8.hours,
  slots: planner(slots: TASKS.shuffle, duration: 16.hours)
)
