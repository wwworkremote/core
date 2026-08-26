# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Make code changes take effect immediately without server restart.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Rotate the dev log instead of letting it grow unbounded -- this box is disk-constrained.
  config.logger = ActiveSupport::TaggedLogging.new(
    Logger.new(Rails.root.join("log", "#{Rails.env}.log"), 5, 20.megabytes)
  )

  config.action_mailer.default_url_options = { host: "localhost", port: 31_000 }

  # Rails rejects non-local Host headers by default. Setting config.hosts
  # explicitly drops Rails' implicit "allow any .localhost subdomain in
  # development" behavior, so the existing dev vhost names have to be listed
  # too, not just the new trusted-LAN .home.arpa names served via AdGuard.
  config.hosts = [
    "localhost", "127.0.0.1", "::1",
    "wwworkremote.localhost", "wwwr.localhost",
    "wwworkremote.home.arpa", "wwwr.home.arpa", "wwr.home.arpa"
  ]

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :solid_cache_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Disable verbose query logs to reduce OTel log volume
  config.active_record.verbose_query_logs = false

  # Disable verbose enqueue logs
  config.active_job.verbose_enqueue_logs = false

  # Disable view annotations for clean logs
  config.action_view.annotate_rendered_view_with_filenames = false

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's condition is not met.
  config.action_controller.raise_on_missing_callback_actions = true

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end
end
