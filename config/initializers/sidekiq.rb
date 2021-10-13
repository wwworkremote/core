# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/throttled'

Sidekiq.default_worker_options = {
  backtrace: true,
  retry: false # No retries, just dead. Use `false` to skip dead queue.
}

sidekiq_redis_url = 'redis://localhost:6379'
sidekiq_redis_url = 'redis://malina103:6379' if Rails.env.production?

Sidekiq.configure_client do |config|
  config.redis = {
    url: sidekiq_redis_url,
    driver: :hiredis,
    network_timeout: 10
  }
end

Sidekiq.configure_server do |config|
  config.redis = {
    url: sidekiq_redis_url,
    driver: :hiredis,
    network_timeout: 10
  }
end

Sidekiq::Throttled.setup!
