# frozen_string_literal: true

role :web, %w[malina101]
role :app, %w[malina101 malina102]
role :cron1, %w[malina101]
role :cron2, %w[malina102]
role :sidekiq, %w[malina102]
role :redis, %w[malina101 malina102]
# role :files, %w[malina104]
role :db, %w[malina103], primary: true

set :sentry_api_token, '0e29254fac624501bae3c56d405d07b26863e9f1485b44c3aa5b12226d5157b7'
set :sentry_organization, 'just3ws'
set :sentry_project, 'outlier_jobs'
set :sentry_repo, 'just3ws/outlier_jobs'
