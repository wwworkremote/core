# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require "active_storage/engine"
require 'action_controller/railtie'
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

NODES_MAP ||= {
  'node01' => 'node05',
  'node02' => 'node01',
  'node03' => 'node02',
  'node04' => 'node03',
  'node05' => 'node04',
  'zalewhol' => 'zalewhol'
}.freeze

NODES_INVERSE_MAP ||= NODES_MAP.invert.freeze

module Nodes # :nodoc:
  HOSTNAME ||= `hostname`.strip.split('.').first.freeze

  def self.upstream
    NODES_MAP[HOSTNAME]
  end

  def self.downstream
    NODES_MAP.invert[HOSTNAME]
  end
end

module Core
  class Application < Rails::Application # :nodoc:
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
