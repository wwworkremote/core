# frozen_string_literal: true

TASKS = %w[
  exe/hackernews
  exe/indeed
  exe/monster\ "a11y"
  exe/monster\ "agile"
  exe/monster\ "airbrake"
  exe/monster\ "ansible"
  exe/monster\ "apache"
  exe/monster\ "api"
  exe/monster\ "aws"
  exe/monster\ "backbone.js"
  exe/monster\ "bash"
  exe/monster\ "bootstrap"
  exe/monster\ "capistrano"
  exe/monster\ "ccnet"
  exe/monster\ "centos"
  exe/monster\ "chargify"
  exe/monster\ "circle\ ci"
  exe/monster\ "clojure"
  exe/monster\ "codesmith\ api"
  exe/monster\ "coffeescript"
  exe/monster\ "couchdb"
  exe/monster\ "css"
  exe/monster\ "cucumber"
  exe/monster\ "devops"
  exe/monster\ "digitalocean"
  exe/monster\ "docker"
  exe/monster\ "ec2"
  exe/monster\ "elasticsearch"
  exe/monster\ "ember.js"
  exe/monster\ "emberjs"
  exe/monster\ "eruby"
  exe/monster\ "etl"
  exe/monster\ "facebook\ graph\ api"
  exe/monster\ "fail2ban"
  exe/monster\ "git"
  exe/monster\ "github\ api"
  exe/monster\ "github"
  exe/monster\ "gitlab"
  exe/monster\ "go"
  exe/monster\ "golang"
  exe/monster\ "google\ analytics"
  exe/monster\ "graph\ api"
  exe/monster\ "hadoop"
  exe/monster\ "heroku"
  exe/monster\ "html"
  exe/monster\ "html5"
  exe/monster\ "http"
  exe/monster\ "hubot"
  exe/monster\ "instagram\ api"
  exe/monster\ "java"
  exe/monster\ "javascript"
  exe/monster\ "jira"
  exe/monster\ "jquery"
  exe/monster\ "jruby"
  exe/monster\ "json\ api"
  exe/monster\ "json"
  exe/monster\ "jsonapi"
  exe/monster\ "jwt"
  exe/monster\ "kafka"
  exe/monster\ "kubernetes"
  exe/monster\ "linux"
  exe/monster\ "lisp"
  exe/monster\ "lodash"
  exe/monster\ "logentries"
  exe/monster\ "markdown"
  exe/monster\ "memcached"
  exe/monster\ "middleware"
  exe/monster\ "mongodb"
  exe/monster\ "mongrel"
  exe/monster\ "monit"
  exe/monster\ "mssql"
  exe/monster\ "mysql"
  exe/monster\ "new\ relic"
  exe/monster\ "nginx"
  exe/monster\ "node.js"
  exe/monster\ "nodejs"
  exe/monster\ "openstack"
  exe/monster\ "passenger"
  exe/monster\ "php"
  exe/monster\ "phpunit"
  exe/monster\ "postgres"
  exe/monster\ "postgresql"
  exe/monster\ "programming"
  exe/monster\ "prolog"
  exe/monster\ "puma"
  exe/monster\ "puppet"
  exe/monster\ "python"
  exe/monster\ "qunit"
  exe/monster\ "rails"
  exe/monster\ "raphael.js"
  exe/monster\ "rds"
  exe/monster\ "react"
  exe/monster\ "redis"
  exe/monster\ "redux"
  exe/monster\ "resque"
  exe/monster\ "rest"
  exe/monster\ "riak"
  exe/monster\ "rollbar"
  exe/monster\ "rspec"
  exe/monster\ "ruby\ on\ rails"
  exe/monster\ "ruby"
  exe/monster\ "rust"
  exe/monster\ "s3"
  exe/monster\ "sass"
  exe/monster\ "scala"
  exe/monster\ "scrum"
  exe/monster\ "semaphore\ ci"
  exe/monster\ "sendgrid\ api"
  exe/monster\ "shell"
  exe/monster\ "sidekiq"
  exe/monster\ "soap"
  exe/monster\ "sql"
  exe/monster\ "stripe"
  exe/monster\ "subversion"
  exe/monster\ "sumo\ logic"
  exe/monster\ "t-sql"
  exe/monster\ "thin"
  exe/monster\ "transact-sql"
  exe/monster\ "trello"
  exe/monster\ "twitter\ api"
  exe/monster\ "typescript"
  exe/monster\ "ubuntu"
  exe/monster\ "uml"
  exe/monster\ "underscore.js"
  exe/monster\ "unicorn"
  exe/monster\ "vagrant"
  exe/monster\ "vertica"
  exe/monster\ "vim"
  exe/monster\ "neovim"
  exe/monster\ "viml"
  exe/monster\ "vmware"
  exe/monster\ "web\ api"
  exe/monster\ "xhtml"
  exe/monster\ "xml"
  exe/monster\ "yaml"
  exe/monster\ "z\ shell"
  exe/monster\ "zsh"
  exe/nexxt
  exe/remoteok
  exe/remotepython
  exe/stackoverflow\ "a11y"
  exe/stackoverflow\ "agile"
  exe/stackoverflow\ "airbrake"
  exe/stackoverflow\ "ansible"
  exe/stackoverflow\ "apache"
  exe/stackoverflow\ "api"
  exe/stackoverflow\ "aws"
  exe/stackoverflow\ "backbone.js"
  exe/stackoverflow\ "bash"
  exe/stackoverflow\ "bootstrap"
  exe/stackoverflow\ "capistrano"
  exe/stackoverflow\ "ccnet"
  exe/stackoverflow\ "centos"
  exe/stackoverflow\ "chargify"
  exe/stackoverflow\ "circle\ ci"
  exe/stackoverflow\ "clojure"
  exe/stackoverflow\ "codesmith\ api"
  exe/stackoverflow\ "coffeescript"
  exe/stackoverflow\ "couchdb"
  exe/stackoverflow\ "css"
  exe/stackoverflow\ "cucumber"
  exe/stackoverflow\ "devops"
  exe/stackoverflow\ "digitalocean"
  exe/stackoverflow\ "docker"
  exe/stackoverflow\ "ec2"
  exe/stackoverflow\ "elasticsearch"
  exe/stackoverflow\ "ember.js"
  exe/stackoverflow\ "emberjs"
  exe/stackoverflow\ "eruby"
  exe/stackoverflow\ "etl"
  exe/stackoverflow\ "facebook\ graph\ api"
  exe/stackoverflow\ "fail2ban"
  exe/stackoverflow\ "git"
  exe/stackoverflow\ "github\ api"
  exe/stackoverflow\ "github"
  exe/stackoverflow\ "gitlab"
  exe/stackoverflow\ "go"
  exe/stackoverflow\ "golang"
  exe/stackoverflow\ "google\ analytics"
  exe/stackoverflow\ "graph\ api"
  exe/stackoverflow\ "hadoop"
  exe/stackoverflow\ "heroku"
  exe/stackoverflow\ "html"
  exe/stackoverflow\ "html5"
  exe/stackoverflow\ "http"
  exe/stackoverflow\ "hubot"
  exe/stackoverflow\ "instagram\ api"
  exe/stackoverflow\ "java"
  exe/stackoverflow\ "javascript"
  exe/stackoverflow\ "jira"
  exe/stackoverflow\ "jquery"
  exe/stackoverflow\ "jruby"
  exe/stackoverflow\ "json\ api"
  exe/stackoverflow\ "json"
  exe/stackoverflow\ "jsonapi"
  exe/stackoverflow\ "jwt"
  exe/stackoverflow\ "kafka"
  exe/stackoverflow\ "kubernetes"
  exe/stackoverflow\ "linux"
  exe/stackoverflow\ "lisp"
  exe/stackoverflow\ "lodash"
  exe/stackoverflow\ "logentries"
  exe/stackoverflow\ "markdown"
  exe/stackoverflow\ "memcached"
  exe/stackoverflow\ "middleware"
  exe/stackoverflow\ "mongodb"
  exe/stackoverflow\ "mongrel"
  exe/stackoverflow\ "monit"
  exe/stackoverflow\ "mssql"
  exe/stackoverflow\ "mysql"
  exe/stackoverflow\ "new\ relic"
  exe/stackoverflow\ "nginx"
  exe/stackoverflow\ "node.js"
  exe/stackoverflow\ "nodejs"
  exe/stackoverflow\ "openstack"
  exe/stackoverflow\ "passenger"
  exe/stackoverflow\ "php"
  exe/stackoverflow\ "phpunit"
  exe/stackoverflow\ "postgres"
  exe/stackoverflow\ "postgresql"
  exe/stackoverflow\ "programming"
  exe/stackoverflow\ "prolog"
  exe/stackoverflow\ "puma"
  exe/stackoverflow\ "puppet"
  exe/stackoverflow\ "python"
  exe/stackoverflow\ "qunit"
  exe/stackoverflow\ "rails"
  exe/stackoverflow\ "raphael.js"
  exe/stackoverflow\ "rds"
  exe/stackoverflow\ "react"
  exe/stackoverflow\ "redis"
  exe/stackoverflow\ "redux"
  exe/stackoverflow\ "resque"
  exe/stackoverflow\ "rest"
  exe/stackoverflow\ "riak"
  exe/stackoverflow\ "rollbar"
  exe/stackoverflow\ "rspec"
  exe/stackoverflow\ "ruby\ on\ rails"
  exe/stackoverflow\ "ruby"
  exe/stackoverflow\ "rust"
  exe/stackoverflow\ "s3"
  exe/stackoverflow\ "sass"
  exe/stackoverflow\ "scala"
  exe/stackoverflow\ "scrum"
  exe/stackoverflow\ "semaphore\ ci"
  exe/stackoverflow\ "sendgrid\ api"
  exe/stackoverflow\ "shell"
  exe/stackoverflow\ "sidekiq"
  exe/stackoverflow\ "soap"
  exe/stackoverflow\ "sql"
  exe/stackoverflow\ "stripe"
  exe/stackoverflow\ "subversion"
  exe/stackoverflow\ "sumo\ logic"
  exe/stackoverflow\ "t-sql"
  exe/stackoverflow\ "thin"
  exe/stackoverflow\ "transact-sql"
  exe/stackoverflow\ "trello"
  exe/stackoverflow\ "twitter\ api"
  exe/stackoverflow\ "typescript"
  exe/stackoverflow\ "ubuntu"
  exe/stackoverflow\ "uml"
  exe/stackoverflow\ "underscore.js"
  exe/stackoverflow\ "unicorn"
  exe/stackoverflow\ "vagrant"
  exe/stackoverflow\ "vertica"
  exe/stackoverflow\ "vim"
  exe/stackoverflow\ "viml"
  exe/stackoverflow\ "vmware"
  exe/stackoverflow\ "web\ api"
  exe/stackoverflow\ "xhtml"
  exe/stackoverflow\ "xml"
  exe/stackoverflow\ "yaml"
  exe/stackoverflow\ "z\ shell"
  exe/stackoverflow\ "zsh"
  exe/weworkremotely
].uniq.freeze

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

    every(cron, roles: [host]) { runner task }
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
  slots: planner(slots: TASKS.shuffle.freeze, duration: 1.day)
)

# every :day, at: '8:08am', roles: [:cron2] do # UTC
#   command 'exe/dice'
# end

every(1.day, roles: [:cron1]) { rake 'pghero:capture_space_stats' }
every(5.minutes, roles: [:cron2]) { rake 'pghero:capture_query_stats' }
