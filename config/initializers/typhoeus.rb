# frozen_string_literal: true

Typhoeus::Config.cache = Typhoeus::Cache::Redis.new(Rails.cache.redis, default_ttl: 600) 
# Typhoeus::Config.cache = Typhoeus::Cache::Rails.new
