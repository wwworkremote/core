# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module WwworkRemote
  class Application < Rails::Application
    config.load_defaults 7.0

    config.active_record.default_timezone = :utc
    config.active_record.schema_format = :sql
    config.generators.system_tests = nil
    config.time_zone = 'UTC'

    # config.autoload_paths << Rails.root.join('app/actions').to_s
    # config.autoload_paths << Rails.root.join('app/lib').to_s

    # config.eager_load_paths << Rails.root.join('app/actions').to_s
    # config.eager_load_paths << Rails.root.join('app/lib').to_s

    # config.paths.add 'lib', eager_load: true
    # config.paths.add 'actions', eager_load: true

    config.hosts << 'core.test'
    config.hosts << 'core.wwworkremote.lan'
    config.hosts << 'localhost'

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.api_only = true
  end
end
