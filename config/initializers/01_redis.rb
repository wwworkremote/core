# frozen_string_literal: true

require 'redis'
require 'hiredis'
require 'redis/connection/hiredis'

REDIS = Redis.new(url: 'redis://localhost:6379', driver: :hiredis)
SIDEKIQ_REDIS = Redis.new(url: 'redis://192.168.0.103:6379', driver: :hiredis)
