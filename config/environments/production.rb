# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

require 'logger'
require 'lograge'
require 'lograge/sql'
require 'lograge/sql/extension'
require 'outlier_jobs/logger'
require 'outlier_jobs/syslog_device'

LOGRAGE_EXCEPTIONS = %w[controller action format id utf8].freeze

Rails.application.configure do # rubocop:disable Metrics/BlockLength
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

  config.lograge_sql.extract_event = proc do |event|
    { name: event.payload[:name], duration: event.duration.to_f.round(2), sql: event.payload[:sql] }
  end

  config.lograge_sql.formatter = proc { |sql_queries| sql_queries }

  config.lograge.formatter = Class.new do |fmt|
    def fmt.call(data)
      { msg: 'Request', request: data }
    end
  end

  config.lograge.custom_payload do |controller|
    ip = begin
      controller.request.remote_ip
    rescue ActionDispatch::RemoteIp::IpSpoofAttackError
      nil
    end

    { ip: ip }
  rescue StandardError => e
    Rails.logger.warn { "Failed to append custom payload: #{e.message}\n#{e.backtrace.join("\n")}" }

    {}
  end

  config.lograge.custom_options = lambda do |event|
    params = event.payload[:params].except(*LOGRAGE_EXCEPTIONS)

    if (file = params[:file]) && file.respond_to?(:headers)
      params[:file] = file.headers
    end

    if (files = params[:files]) && files.respond_to?(:map)
      params[:files] = files.map do |f|
        f.respond_to?(:headers) ? f.headers : f
      end
    end

    output = { params: params.to_query }

    data = (Thread.current[:_method_profiler] || event.payload[:timings])

    if data
      sql = data[:sql]

      if sql
        output[:db] = sql[:duration] * 1000
        output[:db_calls] = sql[:calls]
      end

      redis = data[:redis]

      if redis
        output[:redis] = redis[:duration] * 1000
        output[:redis_calls] = redis[:calls]
      end

      net = data[:net]

      if net
        output[:net] = net[:duration] * 1000
        output[:net_calls] = net[:calls]
      end
    end

    output[:level] = event.payload[:level]
    output[:type] = :rails
    output[:environment] = Rails.env

    output
  rescue StandardError => e
    Rails.logger.warn { "Failed to append custom options: #{e.message}\n#{e.backtrace.join("\n")}" }

    {}
  end

  device = OutlierJobs::SyslogDevice.new('outlierjobs-core')
  logger = OutlierJobs::Logger.new(device)
  logger.default_message = 'N/A'
  logger.before_log = ->(data) { data[:thread_id] = Thread.current.object_id.to_s(36) }

  logger.with_fields = {
    timestamp: Time.now.utc.to_json.tr('"', '').strip.freeze,
    instance_id: Druuid.gen.to_s.freeze,
    pid: Process.pid
  }.freeze

  config.log_tags = [Socket.gethostname, :uuid, :request_id]
  config.log_level = :debug
  config.logger = ActiveSupport::TaggedLogging.new(logger)

  config.lograge.enabled = true
end
