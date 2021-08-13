# frozen_string_literal: true

require 'redis'
require 'hiredis'
require 'redis/connection/hiredis'

REDIS_URL = if Rails.env.production?
              ENV['REDIS_URL'].presence || 'redis://localhost:6379'
            else
              'redis://localhost:6379'
            end

REDIS = Redis.new(url: REDIS_URL, driver: :hiredis)
