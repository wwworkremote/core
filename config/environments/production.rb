# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

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

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = false

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use a different cache store in production.
  config.cache_store = :redis_cache_store, {
    driver: :hiredis,
    namespace: 'oj',
    url: 'redis://localhost:6379'
  }

  # connect_timeout: 30, # Defaults to 20 seconds
  # pool_size: 15,
  # pool_timeout: 15,
  # read_timeout: 15, # Defaults to 1 second
  # reconnect_attempts: 15, # Defaults to 0
  # write_timeout: 15 # Defaults to 1 second

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  config.active_support.disallowed_deprecation = :log

  config.active_support.disallowed_deprecation_warnings = []

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

  config.log_formatter = proc do |severity, time, progname, data|
    data = { msg: data.to_s } unless data.is_a?(Hash)

    tags = current_tags

    data[:tags] = tags if tags.present?

    _call(severity, time, progname, data)
  end

  require 'outlier_jobs/logger'
  logger = OutlierJobs::Logger.new($stdout)

  require 'syslog/logger'
  syslogger = Syslog::Logger.new('outliers-core')
  logger.extend Ougai::Logger.broadcast(syslogger)

  logger.with_fields = {
    timestamp: Time.now.utc.to_json.tr('"', ''),
    instance_id: Druuid.gen.to_s.freeze,
    pid: Process.pid
  }

  config.log_tags = %i[request_id]
  config.logger = ActiveSupport::TaggedLogging.new(logger)
end
