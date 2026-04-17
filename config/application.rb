# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

class Nodes # :nodoc:
  CURRENT = 1
  def self.current = CURRENT
  def self.siblings = []
  def self.upstream = nil
  def self.downstream = nil
  def self.previous = nil
  def self.next = nil
  def self.from(_node_id) = :current
  def self.representation = [1]
end

module Core
  class Application < Rails::Application # :nodoc:
    # Initialize configuration defaults for Rails 8.0.
    config.load_defaults 8.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.generators.system_tests = nil

    # Use Solid Queue for background jobs
    config.active_job.queue_adapter = :solid_queue

    # Use Solid Cache for caching
    config.cache_store = :solid_cache_store

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    # config.api_only = true

    # Lograge configuration for OTel-friendly structured logs
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.custom_options = lambda do |event|
      {
        time: event.time,
        remote_ip: event.payload[:remote_ip],
        user_agent: event.payload[:user_agent],
        # Add OTel context if available
        trace_id: OpenTelemetry::Trace.current_span.context.trace_id.unpack1('H*'),
        span_id: OpenTelemetry::Trace.current_span.context.span_id.unpack1('H*')
      }
    end
  end
end
