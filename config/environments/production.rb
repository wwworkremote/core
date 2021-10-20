# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

require 'wwworkremote/logger'
require 'wwworkremote/syslog_device'

Rails.application.configure do
  # config.require_master_key = true
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'
  config.active_record.dump_schema_after_migration = false
  config.active_support.deprecation = :notify
  config.active_support.disallowed_deprecation = :log
  config.active_support.disallowed_deprecation_warnings = []
  config.cache_classes = true
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.public_file_server.enabled = false

  config.cache_store = :redis_cache_store, {
    driver: :hiredis,
    namespace: 'wwwr:core',
    url: 'redis://localhost:6379/0'
  }

  config.log_formatter = ::Logger::Formatter.new
  config.log_level = :debug
  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end
