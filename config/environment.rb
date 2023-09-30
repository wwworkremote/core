# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'

require_relative 'application'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'wwworkremote'
  c.use_all # enables all instrumentation!
end

Rails.application.initialize!
