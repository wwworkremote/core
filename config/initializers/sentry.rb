# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = 'https://fec1691c37fe4ba0bafe9f02118b1358@o522223.ingest.sentry.io/5858118'

  config.send_default_pii = true

  config.breadcrumbs_logger = %i[sentry_logger active_support_logger http_logger]

  config.enabled_environments = %w[production]
  #
  # config.logger = Sentry::Logger.new(STDOUT)
  #
  # config.inspect_exception_causes_for_exclusion = false
  # config.excluded_exceptions += ['ActionController::RoutingError', 'ActiveRecord::RecordNotFound']
  #
  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 1.0
  # # or
  # config.traces_sampler = lambda do |context|
  #   true
  # end
end
