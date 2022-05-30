# frozen_string_literal: true

# role :web, %w[jagodka105]
#
NODES = %w[node01 node02 node03 node04 node05].freeze

role :app, NODES

role :cron, NODES

# role :cron1, %w[node101]
# role :cron2, %w[node102]

role :sidekiq, NODES

role :redis, NODES

role :db, NODES
