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

require 'sorted_set'

class Nodes # :nodoc:
  ACTUALLY ||= `hostname`.strip.split('.').first.freeze

  HOSTNAME ||= if ACTUALLY == 'zalewhol'
                 'node01'
               else
                 ACTUALLY
               end

  CURRENT ||= HOSTNAME[/\d+$/].to_i

  MAP ||= { 1 => 5, 2 => 1, 3 => 2, 4 => 3, 5 => 4 }.freeze
  UPSTREAM_MAP ||= MAP.invert.freeze

  DOWNSTREAM_NAME_MAP ||= { 'node01' => 2, 'node02' => 3, 'node03' => 4, 'node04' => 5, 'node05' => 1 }.freeze
  UPSTREAM_NAME_MAP ||= { 'node01' => 5, 'node02' => 1, 'node03' => 2, 'node04' => 3, 'node05' => 4 }.freeze

  UPSTREAM ||= MAP[CURRENT]
  DOWNSTREAM ||= UPSTREAM_MAP[CURRENT]

  def self.current
    CURRENT
  end

  def self.siblings
    SortedSet.new(MAP.flatten).to_a - [current]
  end

  def self.upstream
    UPSTREAM
  end

  def self.downstream
    DOWNSTREAM
  end

  def self.previous
    UPSTREAM
  end

  def self.next
    DOWNSTREAM
  end

  def self.from(node_id)
    return :current if node_id == CURRENT
    return :upstream if node_id == 5 && CURRENT == 1
    return :upstream if node_id < CURRENT
    return :downstream if node_id == 1 && CURRENT == 5

    :downstream
  end

  def self.representation
    [upstream, current, downstream]
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
