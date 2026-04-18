# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry-exporter-otlp'

# Defer OTel configuration until after the application is initialized
# to prevent premature loading of ActiveJob, ActionMailer, etc.
Rails.application.config.after_initialize do
  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'wwworkremote'
    c.use 'OpenTelemetry::Instrumentation::Rails'
    c.use 'OpenTelemetry::Instrumentation::PG'
    c.use 'OpenTelemetry::Instrumentation::Faraday'
    # Net::HTTP instrumentation is disabled to avoid SystemStackErrors
  end
end
