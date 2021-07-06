# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = 'https://a9aaf54278e4413da92c138a53495caf@o522223.ingest.sentry.io/5647265'
  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 0.5
  # or
  config.traces_sampler = lambda do |_context|
    true
  end
end
