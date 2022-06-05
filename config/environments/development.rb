# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.action_controller.enable_fragment_cache_logging = true
  config.action_controller.perform_caching = true
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.cache_classes = false
  config.consider_all_requests_local = true
  config.eager_load = false
  config.action_cable.disable_request_forgery_protection = true
  config.server_timing = true

  config.cache_store = :redis_cache_store, {
    url: 'redis://localhost:6379/0',
    driver: :hiredis,
    namespace: 'wwwr:dash'
  }

  config.log_formatter = ::Logger::Formatter.new
  config.log_level = :info
  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)
end
