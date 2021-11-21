# frozen_string_literal: true

role :web, %w[jagodka105]

role :app, %w[malina101 malina102 malina103 jagodka105]

role :cron, %w[malina101 malina102]

role :cron1, %w[malina101]
role :cron2, %w[malina102]

role :sidekiq, %w[jagodka105]

role :redis, %w[jagodka105 malina101 malina102 malina103]

role :db, %w[malina108], primary: true
