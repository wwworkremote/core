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
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.cache_store = :redis_cache_store, {
    url: 'redis://localhost:6379/0',
    driver: :hiredis,
    namespace: 'wwwr::dev'
  }

  config.log_formatter = proc do |severity, time, progname, data|
    data = { msg: data.to_s } unless data.is_a?(Hash)

    tags = current_tags

    data[:tags] = tags if tags.present?

    _call(severity, time, progname, data)
  end
  config.colorize_logging = !Rails.env.production?
  config.log_level = :debug

  require 'wwwork_remote/logger'
  logger = WwworkRemote::Logger.new($stdout)

  logger.with_fields = {
    timestamp: Time.now.utc.to_json.tr('"', ''),
    instance_id: Druuid.gen.to_s.freeze,
    pid: Process.pid
  }

  config.log_tags = %i[request_id]
  config.logger = ActiveSupport::TaggedLogging.new(logger)
end
