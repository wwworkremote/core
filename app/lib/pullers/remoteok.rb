# frozen_string_literal: true

module Pullers
  module RemoteOK
    module_function

    def pull(*)
      service = RemoteOK::Feed.new

      service.call

      service.data.dig('rss', 'channel', 'item')
    end
    # remote-dev-jobs.rss

    def client
      Faraday.new do |f|
        f.request :retry, max: 3, interval: 0.05, interval_randomness: 0.5, backoff_factor: 3, max_interval: 900

        f.headers[:user_agent] = 'WwworkRemote::RemoteOK/1.0'

        f.ssl[:verify] = false

        f.url_prefix = 'https://remoteok.io'

        f.headers[:accept] = 'application/xml'

        f.use :instrumentation
        f.response :xml, content_type: /\bxml$/
        f.response :encoding

        f.adapter :typhoeus
      end
    end
  end
end
