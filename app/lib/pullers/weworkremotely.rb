# frozen_string_literal: true

module Pullers
  module WeWorkRemotely
    module_function

    def pull(*)
      service = WeWorkRemotely::Feed.new

      service.call

      service.data.dig('rss', 'channel', 'item')
    end

    def client
      Faraday.new do |f|
        f.request :retry, max: 3, interval: 0.05, interval_randomness: 0.5, backoff_factor: 3, max_interval: 900

        f.headers[:user_agent] = 'WwworkRemote::WeWorkRemotely/1.0'

        f.url_prefix = 'https://weworkremotely.com/'
        f.path_prefix = 'categories'

        f.headers[:accept] = 'application/rss+xml;charset=utf-8'
        f.headers[:accept_charset] = 'charset=utf-8'

        f.use :instrumentation
        f.response :xml, content_type: /\bxml$/
        f.response :encoding

        # f.adapter :typhoeus
      end
    end
  end
end
