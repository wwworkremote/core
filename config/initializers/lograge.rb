# frozen_string_literal: true

if Rails.env.production?
  require 'lograge'
  require 'lograge/sql'
  require 'lograge/sql/extension'

  LOGRAGE_EXCEPTIONS = %w[controller action format id utf8].freeze

  Rails.application.configure do
    config.lograge.enabled = true

    # Instead of extracting event as Strings, extract as Hash. You can also
    # extract additional fields to add to the formatter
    config.lograge_sql.extract_event = proc do |event|
      { name: event.payload[:name], duration: event.duration.to_f.round(2), sql: event.payload[:sql] }
    end

    # Format the array of extracted events
    config.lograge_sql.formatter = proc do |sql_queries|
      sql_queries
    end

    config.lograge.keep_original_rails_log = false
    # config.lograge.logger = ActiveSupport::Logger.new(Rails.root.join("/log/lograge_#{Rails.env}.log"))

    config.lograge.formatter = Lograge::Formatters::Json.new

    config.lograge.custom_payload do |controller|
      ip = begin
        controller.request.remote_ip
      rescue ActionDispatch::RemoteIp::IpSpoofAttackError
        nil
      end

      {
        ip: ip
      }
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
  end
end
