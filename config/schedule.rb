# frozen_string_literal: true

TERMS = %w[
  a11y
  active\ directory
  active\ server\ pages\
  activex
  agile
  airbrake
  amazon\ rds
  ansible
  apache
  api
  asp
  asp.net
  aws\ ec2
  aws\ rds
  aws\ s3
  backbone.js
  bash
  bootstrap
  c#
  capistrano
  ccnet
  centos
  chargify
  circleci
  clojure
  codesmith\ api
  coffeescript
  coldfusion
  couchdb
  cruisecontrol.net
  css
  cucumber
  devops
  digitalocean
  docker
  elasticsearch
  ember.js
  eruby
  etl
  facebook\ graph\ api
  fail2ban
  git
  github
  github\ api
  gitlab
  go
  golang
  google\ analytics
  hadoop
  heroku
  html
  html/sass
  html5
  http
  hubot
  iis
  imb\ rational
  instagram\ api
  internet\ information\ services
  java
  java\ server\ pages
  java\ websphere
  javalite
  javascript
  jetty
  jira
  jquery
  jruby
  json
  json\ api
  jsonapi
  jsp
  jwt
  kafka
  kubernetes
  linux
  lisp
  lodash
  logentries
  markdown
  mbunit
  memcached
  mercurial
  microsoft\ access
  microsoft\ biztalk\ server
  microsoft\ sql\ server
  microsoft\ sql\ server\ reporting\ services
  middleware
  mongodb
  mongrel
  monit
  mysql
  nant
  new\ relic
  nginx
  nlog
  node.js
  nodejs
  nunit
  openstack
  oracle\ fusion
  packer
  passenger
  php
  phpunit
  postgres
  postgresql
  prolog
  puma
  puppet
  python
  qunit
  rails
  raphael.js
  react
  redis
  redux
  resque
  rest
  riak
  rollbar
  rspec
  ruby
  ruby\ on\ rails
  rust
  sass
  scala
  scrum
  semaphore\ ci
  sendgrid\ api
  sharepoint
  shell
  sidekiq
  soap
  solomon\ accounting\ software
  sourcegear\ vault
  sql
  ssrs
  stripe
  stun
  subsonic\ orm
  subversion
  sumo\ logic
  t-sql
  thin
  trac
  transact-sql
  trello
  twitter\ api
  typescript
  ubuntu
  uml
  underscore.js
  unicorn
  vagrant
  vb.net
  vba
  vbscript
  vertica
  vim
  viml
  visual\ basic
  visual\ basic\ .net
  visual\ basic\ for\ applications
  visual\ interdev
  visual\ j++
  visual\ sourcesafe
  visual\ studio\ .net
  visual\ studio\ team\ services
  vmware
  watir
  web\ api
  windows\ 2000\ server
  windows\ 98
  windows\ nt
  windows\ server
  xhtml
  xml
  yaml
  z\ shell
  zsh
].shuffle.freeze

TASKS_WITH_TERMS = %w[monster stackoverflow].flat_map { |task| TERMS.flat_map { |term| "#{task} #{term}" } }.shuffle.freeze

TASKS = %w[
  hackernews
  indeed
  nexxt
  remoteok
  remotepython
  weworkremotely
].concat(TASKS_WITH_TERMS).shuffle.freeze

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

every('40 * * * *', roles: [:cron1]) { runner 'exe/sources' }
every('10 * * * *', roles: [:cron2]) { runner 'exe/sources' }

every('15 * * * *', roles: [:cron1]) { runner 'exe/messages' }
every('45 * * * *', roles: [:cron2]) { runner 'exe/messages' }

every('50 * * * *', roles: [:cron1]) { runner 'exe/tags' }
every('20 * * * *', roles: [:cron2]) { runner 'exe/tags' }

every('25 * * * *', roles: [:cron1]) { runner 'exe/moment' }
every('55 * * * *', roles: [:cron2]) { runner 'exe/moment' }

scheduler(
  start_at: Date.today.to_datetime.to_time.utc,
  slots: planner(slots: TASKS.shuffle, duration: 7.hours)
)

every :day, at: '8:08am', roles: [:cron2] do # UTC
  command 'exe/dice'
end

scheduler(
  start_at: Date.today.to_datetime.to_time.utc + 8.hours,
  slots: planner(slots: TASKS.shuffle, duration: 16.hours)
)

every(1.day, roles: [:cron1]) { rake 'pghero:capture_space_stats' }
every(5.minutes, roles: [:cron2]) { rake 'pghero:capture_query_stats' }
