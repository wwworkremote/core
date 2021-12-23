# frozen_string_literal: true

# https://remotive.io/api-documentation
# https://remotive.io/api/remote-jobs/categories
module Pullers
  module Remotive
    module_function

    def pull(term:)
      service = Pullers::Remotive::Jobs.new(term: term.presence)

      service.call

      service.data['jobs']
    end

    def client
      Faraday.new do |f|
        f.request :retry, max: 3, interval: 0.05, interval_randomness: 0.5, backoff_factor: 3, max_interval: 900

        f.headers[:user_agent] = 'WwworkRemote::Remotive/1.0'

        f.url_prefix = 'https://remotive.io'
        f.path_prefix = 'api/remote-jobs'

        f.headers[:accept] = 'application/json; charset=utf-8'

        f.use :instrumentation
        f.response :json, content_type: /\bjson$/
        f.response :encoding
      end
    end
  end
end
