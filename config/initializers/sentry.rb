# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = 'https://fec1691c37fe4ba0bafe9f02118b1358@o522223.ingest.sentry.io/5858118'
  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 0.5
  # or
  config.traces_sampler = lambda do |context|
    true
  end
end
