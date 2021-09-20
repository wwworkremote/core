# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

require 'logger'
require 'syslog'
require 'syslog/logger'
require 'outlier_jobs/logger'

module ActiveSupport
  module TaggedLogging
    module Formatter
      def call(severity, time, progname, data)
        data = { msg: data.to_s } unless data.is_a?(Hash)

        tags = current_tags

        data[:tags] = tags if tags.present?

        _call(severity, time, progname, data)
      end
    end
  end
end

class SyslogDevice
  LEVEL_MAP = {
    ::Logger::UNKNOWN => Syslog::LOG_ALERT,
    ::Logger::FATAL => Syslog::LOG_ERR,
    ::Logger::ERROR => Syslog::LOG_WARNING,
    ::Logger::WARN => Syslog::LOG_NOTICE,
    ::Logger::INFO => Syslog::LOG_INFO,
    ::Logger::DEBUG => Syslog::LOG_DEBUG
  }.freeze

  def syslog_level
    LEVEL_MAP[Rails.logger&.level || ::Logger::DEBUG]
  end

  def initialize(prog_name)
    @log = Syslog.open(prog_name)
    update_syslog_mask
  end

  def write(message)
    update_syslog_mask
    @log.log(syslog_level, message)
  end

  def update_syslog_mask
    Syslog.mask = Syslog::LOG_UPTO(syslog_level) if Syslog.mask != Syslog::LOG_UPTO(syslog_level)
  end

  def close
    @log.close
  end
end

Rails.application.configure do
  # config.require_master_key = true
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'
  config.active_record.dump_schema_after_migration = false
  config.active_support.deprecation = :notify
  config.active_support.disallowed_deprecation = :log
  config.active_support.disallowed_deprecation_warnings = []
  config.cache_classes = true
  config.cache_store = :redis_cache_store, { driver: :hiredis, namespace: 'oj', url: 'redis://localhost:6379' }
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.public_file_server.enabled = false

  config.log_formatter = proc do |severity, time, progname, data|
    data = { msg: data.to_s } unless data.is_a?(Hash)
    tags = current_tags
    data[:tags] = tags if tags.present?
    _call(severity, time, progname, data)
  end

  device = SyslogDevice.new('outlierjobs-core')
  logger = OutlierJobs::Logger.new(device)
  logger.default_message = 'N/A'
  logger.before_log = ->(data) { data[:thread_id] = Thread.current.object_id.to_s(36) }

  logger.with_fields = { timestamp: Time.now.utc.to_json.tr('"', ''), instance_id: Druuid.gen.to_s.freeze, pid: Process.pid }

  config.log_tags = %i[request_id]
  config.log_level = :debug
  config.logger = ActiveSupport::TaggedLogging.new(logger)
end

# logger = OutlierJobs::Logger.new(SyslogDevice.new)
# logger = Ougai::Logger.new(device)
# logger.level = Ougai::Logger::WARN
# syslogger = Syslog::Logger.new('outliers-core')
# logger.extend Ougai::Logger.broadcast(syslogger)
# config.log_level = logger.level
# logger.level = Ougai::Logger::DEBUG
