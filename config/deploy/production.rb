# frozen_string_literal: true

role :web, %w[malina101]
role :app, %w[malina101 malina102]
role :cron, %w[malina102]
role :sidekiq, %w[malina102]
role :redis, %w[malina101 malina102]
role :files, %w[malina104]
role :db, %w[malina103], primary: true
