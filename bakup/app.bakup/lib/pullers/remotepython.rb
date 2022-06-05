# frozen_string_literal: true

module Pullers
  module RemotePython
    module_function

    def pull(*)
      service = RemotePython::Feed.new

      service.call

      return [] if service.data.blank?

      service.data.dig('rss', 'channel', 'item')
    end

    def client
      Faraday.new do |f|
        f.request :retry, max: 3, interval: 0.05, interval_randomness: 0.5, backoff_factor: 3, max_interval: 900

        f.headers[:user_agent] = 'WwworkRemote::RemotePython/1.0'

        f.url_prefix = 'https://www.remotepython.com'
        f.path_prefix = 'latest/jobs/feed'

        f.headers[:accept] = 'application/rss+xml;charset=utf-8'

        f.use :instrumentation
        f.response :xml, content_type: /\bxml$/
        f.response :encoding
      end
    end
  end
end
