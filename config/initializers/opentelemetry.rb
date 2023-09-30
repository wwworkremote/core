# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'

RailsTracer = OpenTelemetry.tracer_provider.tracer('rails')
