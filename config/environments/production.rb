# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

require 'outlier_jobs/logger'
require 'outlier_jobs/syslog_device'

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

  prog_name = 'wwwr::core'

  device = OutlierJobs::SyslogDevice.new(prog_name)
  logger = OutlierJobs::Logger.new(device)
  logger.default_message = 'N/A'
  logger.before_log = ->(data) { data[:thread_id] = Thread.current.object_id.to_s(36) }

  logger.with_fields = {
    name: prog_name,
    hostname: Socket.gethostname,
    instance_id: Druuid.gen.to_s.freeze,
    pid: Process.pid
  }.freeze

  config.log_level = :debug
  config.logger = logger
end
