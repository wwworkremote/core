# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry-exporter-otlp'

# Defer OTel configuration until after the application is initialized
# and ensure it handles forking correctly for macOS safety
Rails.application.config.after_initialize do
  # Disable OTel if we are in a sub-process that hasn't fully booted
  # or if we are on macOS and want to avoid the fork segfault
  next if ENV['SKIP_OTEL'] || (defined?(Puma) && Puma.respond_to?(:jruby?) && Puma.jruby?)

  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'wwworkremote'
    c.use 'OpenTelemetry::Instrumentation::Rails'
    c.use 'OpenTelemetry::Instrumentation::PG'
    c.use 'OpenTelemetry::Instrumentation::Faraday'
  end
end
