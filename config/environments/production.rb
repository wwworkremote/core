# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'
  config.active_support.deprecation = :notify
  config.active_support.disallowed_deprecation = :log
  config.active_support.disallowed_deprecation_warnings = []
  config.active_support.report_deprecations = false
  config.cache_classes = true
  config.cache_store = :null_store
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.public_file_server.enabled = false

  config.log_formatter = ::Logger::Formatter.new
  config.log_level = :debug
  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)
end
