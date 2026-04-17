# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry-exporter-otlp'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'wwworkremote'
  c.use 'OpenTelemetry::Instrumentation::Rails'
  c.use 'OpenTelemetry::Instrumentation::PG'
  c.use 'OpenTelemetry::Instrumentation::Faraday'
  c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
  c.use 'OpenTelemetry::Instrumentation::ActiveSupport'
  c.use 'OpenTelemetry::Instrumentation::ActiveJob'
end
