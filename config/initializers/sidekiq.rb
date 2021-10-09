# frozen_string_literal: true

require_relative 'redis'

require 'sidekiq'
require 'sidekiq/api'

# Sidekiq.default_worker_options = {
#   backtrace: true,
#   retry: false # No retries, just dead. Use `false` to skip dead queue.
# }

# Sidekiq.configure_client do |config|
#   config.redis = {
#     url: 'redis://malina103:6379',
#     driver: :hiredis,
#     network_timeout: 10
#   }
# end

# Sidekiq.configure_server do |config|
#   config.redis = {
#     url: 'redis://malina103:6379',
#     driver: :hiredis,
#     network_timeout: 10
#   }
# end
