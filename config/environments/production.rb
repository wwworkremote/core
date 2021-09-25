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
  config.cache_store = :redis_cache_store, { driver: :hiredis, namespace: 'oj', url: 'redis://localhost:6379' }
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.public_file_server.enabled = false

  # config.cache_store = :redis_cache_store, {
  #   connect_timeout: 30, # Defaults to 20 seconds
  #   driver: :hiredis,
  #   namespace: 'core',
  #   pool_size: 5,
  #   pool_timeout: 5,
  #   read_timeout: 0.2, # Defaults to 1 second
  #   reconnect_attempts: 3, # Defaults to 0
  #   url: 'redis://localhost:6379',
  #   write_timeout: 0.2 # Defaults to 1 second
  # }

  prog_name = 'outlierjobs-core'

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
