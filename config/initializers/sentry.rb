
# frozen_string_literal: true

if Rails.env.production?
  Sentry.init do |config|
config.dsn = 'https://129c7bee400f4967828bee2b066b57f5@o522223.ingest.sentry.io/6002256'
    config.breadcrumbs_logger = %i[active_support_logger http_logger]

    # config.traces_sample_rate = 1.0
    config.traces_sampler = ->(context) { true }
  end
end
