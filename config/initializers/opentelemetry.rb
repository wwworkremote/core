# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry-exporter-otlp'

# Defer OTel configuration until after the application is initialized
# and ensure it handles forking correctly for macOS safety
Rails.application.config.after_initialize do
  # Disable OTel if we are in a sub-process that hasn't fully booted
  # or if we are on macOS and want to avoid the fork segfault
  # Also disable if explicitly requested
  next if ENV['SKIP_OTEL'] || (defined?(Puma) && Puma.respond_to?(:jruby?) && Puma.jruby?)

  # MacOS Fork Safety: OpenTelemetry can crash if initialized before fork.
  # Solid Queue and Puma both fork.
  if RUBY_PLATFORM.include?('darwin') && !defined?(Puma) && !defined?(SolidQueue)
    # If we are in the master process on Mac, we often want to defer SDK start
    # but for local dev we just want it to not scream if it fails.
  end

  begin
    OpenTelemetry::SDK.configure do |c|
      c.service_name = 'wwworkremote'
      c.use 'OpenTelemetry::Instrumentation::Rails'
      c.use 'OpenTelemetry::Instrumentation::PG'
      c.use 'OpenTelemetry::Instrumentation::Faraday'
      c.use 'OpenTelemetry::Instrumentation::RubyLLM'
    end
  rescue StandardError => e
    Rails.logger.warn "[OTel] Failed to initialize: #{e.message}"
  end
end
