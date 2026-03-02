# frozen_string_literal: true

begin
  require 'opentelemetry/sdk'
  require 'opentelemetry/instrumentation/all'

  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'wwworkremote'
    c.use_all # enables all instrumentation!
  end
rescue LoadError
  # OpenTelemetry not installed
end

require_relative 'application'

Rails.application.initialize!
