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
  config.cache_store = :redis_cache_store, { driver: :hiredis, url: 'redis://localhost:6379', namespace: 'wwwr' }
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.public_file_server.enabled = false

  # prog_name = 'wwwr::core'

  # device = WwworkRemote::SyslogDevice.new(prog_name)
  # logger = WwworkRemote::Logger.new(device)
  # logger.default_message = 'N/A'
  # logger.before_log = ->(data) { data[:thread_id] = Thread.current.object_id.to_s(36) }

  # logger.with_fields = {
  #   name: prog_name,
  #   hostname: Socket.gethostname,
  #   instance_id: Druuid.gen.to_s.freeze,
  #   pid: Process.pid
  # }.freeze

  config.log_level = :debug
  # config.logger = logger

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end
