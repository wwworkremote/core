# frozen_string_literal: true

if defined?(OpenTelemetry)
  require 'opentelemetry/sdk'
  require 'opentelemetry/instrumentation/all'

  # RailsTracer = OpenTelemetry.tracer_provider.tracer('rails')
end
