# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store
  config.action_dispatch.show_exceptions = :none
  config.logger = Logger.new($stdout)
  config.log_level = :warn
  config.hosts = [".example.com", "localhost", "127.0.0.1"]
  config.action_controller.allow_forgery_protection = false
  config.active_storage.service = :test
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.action_controller.raise_on_missing_callback_actions = true

  config.active_job.queue_adapter = :solid_queue

  config.after_initialize do
    Ahoy.geocode = false

    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.raise = true # Raise an error if an N+1 query is detected
  end
end
