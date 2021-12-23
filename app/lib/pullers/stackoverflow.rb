# frozen_string_literal: true

module Pullers
  module StackOverflow
    module_function

    def pull(term: nil)
      service = StackOverflow::Jobs::Feed.new(term: term.presence)

      service.call

      service.data.dig('rss', 'channel', 'item')
    end

    def client
      Faraday.new do |f|
        f.request :retry, max: 3, interval: 0.05, interval_randomness: 0.5, backoff_factor: 3, max_interval: 900

        f.headers[:user_agent] = 'WwworkRemote::StackOverflow/1.0'

        f.url_prefix = 'https://stackoverflow.com'
        f.path_prefix = 'jobs'

        f.headers[:accept] = 'application/rss+xml;charset=utf-8'

        f.use :instrumentation
        f.response :xml, content_type: /\bxml$/
        f.response :encoding
      end
    end
  end
end
