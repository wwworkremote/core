# frozen_string_literal: true

module Searches
  TERMS = [
    'a11y',
    'agile',
    'airbrake',
    'ansible',
    'apache',
    'api',
    'aws',
    'backbone.js',
    'bash',
    'bootstrap',
    'capistrano',
    'ccnet',
    'centos',
    'chargify',
    'circle ci',
    'clojure',
    'codesmith api',
    'coffeescript',
    'couchdb',
    'css',
    'cucumber',
    'devops',
    'digitalocean',
    'docker',
    'ec2',
    'elasticsearch',
    'ember.js',
    'emberjs',
    'eruby',
    'etl',
    'facebook graph api',
    'graph api',
    'fail2ban',
    'git',
    'github api',
    'github',
    'gitlab',
    'go',
    'golang',
    'google analytics',
    'hadoop',
    'heroku',
    'html',
    'html5',
    'http',
    'hubot',
    'instagram api',
    'java',
    'javascript',
    'jira',
    'jquery',
    'jruby',
    'json api',
    'json',
    'jsonapi',
    'jwt',
    'kafka',
    'kubernetes',
    'linux',
    'lisp',
    'lodash',
    'logentries',
    'markdown',
    'memcached',
    'middleware',
    'mongodb',
    'mongrel',
    'monit',
    'mssql',
    'mysql',
    'new relic',
    'nginx',
    'node.js',
    'nodejs',
    'openstack',
    'passenger',
    'php',
    'phpunit',
    'postgres',
    'postgresql',
    'prolog',
    'puma',
    'puppet',
    'python',
    'qunit',
    'rails',
    'raphael.js',
    'rds',
    'react',
    'redis',
    'redux',
    'resque',
    'rest',
    'riak',
    'rollbar',
    'rspec',
    'ruby on rails',
    'ruby',
    'rust',
    's3',
    'sass',
    'scala',
    'scrum',
    'semaphore ci',
    'sendgrid api',
    'shell',
    'sidekiq',
    'soap',
    'sql',
    'stripe',
    'subversion',
    'sumo logic',
    't-sql',
    'thin',
    'transact-sql',
    'trello',
    'twitter api',
    'typescript',
    'ubuntu',
    'uml',
    'underscore.js',
    'unicorn',
    'vagrant',
    'vertica',
    'vim',
    'viml',
    'vmware',
    'web api',
    'xhtml',
    'xml',
    'yaml',
    'z shell',
    'zsh'
  ].uniq.shuffle.freeze

  SEARCHES = {
    'hackernews' => [],
    'indeed' => [],
    'monster' => TERMS.shuffle.freeze,
    'nexxt' => [],
    'remoteok' => [],
    'remotepython' => [],
    'stackoverflow' => TERMS.shuffle.freeze,
    'weworkremotely' => []
  }.freeze

  module_function

  def searches
    SEARCHES.each_pair.each_with_object([]) do |(k, v), o|
      o << [k, 'programming']
      v.each { |term| o << [k, term] }
    end.shuffle.freeze
  end
end

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

    cmd = task.first
    term = task.last

    next if task.to_s.strip.empty?

    host = hosts[i.even? ? 0 : 1]

    every(cron, roles: [host]) { runner "exe/#{cmd} \"#{term}\"" }
  end
end

every('40 * * * *', roles: [:cron1]) { runner 'exe/sources' }
every('10 * * * *', roles: [:cron2]) { runner 'exe/sources' }

every('15 * * * *', roles: [:cron1]) { runner 'exe/messages' }
every('45 * * * *', roles: [:cron2]) { runner 'exe/messages' }

every('50 * * * *', roles: [:cron1]) { runner 'exe/tags' }
every('20 * * * *', roles: [:cron2]) { runner 'exe/tags' }

every('25 * * * *', roles: [:cron1]) { runner 'exe/moment' }
every('55 * * * *', roles: [:cron2]) { runner 'exe/moment' }

# scheduler(start_at: Date.today.to_datetime.to_time.utc          , slots: planner(slots: TASKS.shuffle, duration:  7.hours))
# scheduler(start_at: Date.today.to_datetime.to_time.utc + 8.hours, slots: planner(slots: TASKS.shuffle, duration: 16.hours))
scheduler(
  start_at: Date.today.to_datetime.to_time.utc,
  slots: planner(slots: Searches.searches, duration: 1.day)
)

# every :day, at: '8:08am', roles: [:cron2] do # UTC
#   command 'exe/dice'
# end

every(1.day, roles: [:cron1]) { rake 'pghero:capture_space_stats' }
every(5.minutes, roles: [:cron2]) { rake 'pghero:capture_query_stats' }
