# frozen_string_literal: true

role :web, %w[jagodka105]

role :app, %w[malina101 malina102 malina103]

role :cron1, %w[malina101]
role :cron2, %w[malina102]
role :cron3, %w[malina103]

role :redis, %w[malina101 malina102 malina103]

role :db, %w[malina108], primary: true
