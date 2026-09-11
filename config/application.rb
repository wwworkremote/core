# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# rubocop:disable-next Style/ClassAndModuleChildren
module WwworkRemote
  class Application < Rails::Application # :nodoc:
    # Initialize configuration defaults for Rails 8.1.
    config.load_defaults 8.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.generators.system_tests = nil

    # Add Packwerk packages to autoload paths
    # We add the individual app/* directories so that Zeitwerk sees them as roots
    Rails.root.glob("packages/*/app/*").each do |path|
      config.autoload_paths << path if File.directory?(path)
    end

    # Use Solid Queue as the default for reliable background processing
    config.active_job.queue_adapter = :solid_queue

    # Use Solid Cache for caching
    config.cache_store = :solid_cache_store

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    # config.api_only = true

    # Use structured JSON logging for OTel-friendly logs and disable ANSI colors
    config.colorize_logging = false
    config.log_formatter = proc do |severity, datetime, progname, msg|
      log_entry = {
        level: severity,
        time: datetime.iso8601(3),
        progname: progname,
        message: msg.is_a?(String) ? msg : msg.inspect,
        # Add OTel context for trace-log correlation
        trace_id: OpenTelemetry::Trace.current_span.context.trace_id.unpack1("H*"),
        span_id: OpenTelemetry::Trace.current_span.context.span_id.unpack1("H*")
      }.compact.to_json
      "#{log_entry}\n"
    end

    # Lograge configuration for OTel-friendly structured request logs
    config.after_initialize do
      config.lograge.enabled = true
      config.lograge.support_action_cable = true
      config.lograge.formatter = Lograge::Formatters::Json.new
      config.lograge.custom_options = lambda do |event|
        {
          time: event.time,
          remote_ip: event.payload[:remote_ip],
          user_agent: event.payload[:user_agent],
          # Add OTel context if available for trace correlation
          trace_id: OpenTelemetry::Trace.current_span.context.trace_id.unpack1("H*"),
          span_id: OpenTelemetry::Trace.current_span.context.span_id.unpack1("H*")
        }
      end
    end
  end
end
