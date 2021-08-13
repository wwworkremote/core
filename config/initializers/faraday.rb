# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

require 'typhoeus/adapters/faraday'
require 'typhoeus/cache/redis'

Typhoeus::Config.cache = Typhoeus::Cache::Redis.new(
  Rails.cache.redis,
  default_ttl: 30.minutes
)
