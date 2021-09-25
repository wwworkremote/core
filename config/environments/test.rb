# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.action_controller.allow_forgery_protection = false
  config.action_controller.perform_caching = true
  config.action_dispatch.show_exceptions = true
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.cache_classes = true
  config.consider_all_requests_local = true
  config.eager_load = false
  config.cache_store = :redis_cache_store, {
    url: 'redis://localhost:6379/0',
    driver: :hiredis,
    namespace: 'wwwr::test'
  }
end
