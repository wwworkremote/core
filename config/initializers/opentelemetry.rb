# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'wwworkremote'
  c.use_all # enables all instrumentation!
end

RailsTracer = OpenTelemetry.tracer_provider.tracer('rails')
