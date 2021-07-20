# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = 'https://1531d06a21294acdaff63005ef74c803@o522223.ingest.sentry.io/5872988'
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
