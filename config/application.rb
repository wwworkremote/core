# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

require 'socket'
HOSTNAME = Socket.gethostname.split('.').first.freeze

module WwworkRemote
  class Application < Rails::Application
    config.load_defaults 7.0

    config.generators.system_tests = nil
    config.time_zone = 'UTC'

    config.hosts << "#{HOSTNAME}.wwworkremote.com"
    config.hosts << HOSTNAME.to_s
    config.hosts << 'localhost'

    config.api_only = true
  end
end
