# frozen_string_literal: true

module Pullers
  module Nexxt
    module_function

    def pull(term: nil)
      service = Nexxt::Feed.new(term: term.presence)

      service.call

      service.data.dig('rss', 'channel', 'item')
    end

    def client
      Faraday.new do |f|
        f.request :retry, max: 5, interval: 0.05, interval_randomness: 0.5, backoff_factor: 3, max_interval: 900

        f.headers[:user_agent] = 'WwworkRemote::Nexxt/1.0'

        f.url_prefix = 'https://www.nexxt.com/'
        f.path_prefix = 'jobs/search/rss'

        f.headers[:accept] = 'text/xml;charset=utf-8'

        f.use :instrumentation
        f.response :xml, content_type: /\bxml$/
        f.response :encoding

        f.adapter :typhoeus
      end
    end
  end
end
