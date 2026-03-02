# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry-exporter-otlp'

OpenTelemetry::SDK.configure do |c|
  c.use_all # enables all instrumentation!
end
