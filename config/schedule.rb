# frozen_string_literal: true

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

FETCHERS = %w[hackernews indeed monster\ api monster\ bash monster\ css monster\ git monster\ github monster\ gitlab monster\ golang monster\ javascript monster\ jquery monster\ nodejs monster\ postgres monster\ postgresql monster\ python monster\ rails monster\ redis monster\ rspec monster\ ruby monster\ sass monster\ sidekiq monster\ sql monster\ vim monster\ zsh nexxt remoteok remotepython stackoverflow\ api stackoverflow\ bash stackoverflow\ css stackoverflow\ git stackoverflow\ github stackoverflow\ gitlab stackoverflow\ golang stackoverflow\ javascript stackoverflow\ jquery stackoverflow\ nodejs stackoverflow\ postgres stackoverflow\ postgresql stackoverflow\ python stackoverflow\ rails stackoverflow\ redis stackoverflow\ rspec stackoverflow\ ruby stackoverflow\ sass stackoverflow\ sidekiq stackoverflow\ sql stackoverflow\ vim stackoverflow\ zsh weworkremotely].freeze

module Cronner
  module_function

  def planner(slots:, duration:)
    count_from = ((duration.to_f / slots.count) / 2).to_i
    count_by = duration.to_f / (slots.count + 1)

    count_from.step(duration, count_by).map(&:to_i).zip(slots)
  end

  def scheduler(start_at:, slots:)
    slots.each do |slot|
      time = start_at + slot.first

      cron = "#{time.min} #{time.hour} * * *"
      task = slot.last

      every(cron) { "exe/#{task}" }
    end
  end
end
# start_at: Date.today.to_datetime.to_time.utc,
Cronner.scheduler(
  start_at: Date.today.to_datetime.to_time.utc,
  slots: Cronner.planner(slots: FETCHERS, duration: 7.hours)
)

every :day, at: '8:08am', roles: [:cron] do # UTC
  command 'exe/dice'
end

Cronner.scheduler(
  start_at: Date.today.to_datetime.to_time.utc + 8.hours,
  slots: Cronner.planner(slots: FETCHERS, duration: 16.hours)
)
