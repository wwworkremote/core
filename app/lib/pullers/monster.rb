# frozen_string_literal: true

module Pullers
  module Monster
    module_function

    def pull(term: nil)
      service = Monster::Feed.new(term: term.presence)

      service.call

      service.data.dig('rss', 'channel', 'item')
    end

    def client
      Faraday.new do |f|
        f.request :retry, max: 3, interval: 0.05, interval_randomness: 0.5, backoff_factor: 3, max_interval: 900

        f.headers[:user_agent] = 'WwworkRemote::Monster/1.0'

        f.ssl[:verify] = false

        f.url_prefix = 'https://rss.jobsearch.monster.com'
        f.path_prefix = 'rssquery.ashx'

        f.headers[:accept] = 'application/rss+xml;charset=utf-8'
        f.headers[:accept_charset] = 'charset=utf-8'

        f.use :instrumentation

        f.response :xml, content_type: /\bxml$/
        f.response :encoding

        f.adapter :typhoeus
      end
    end
  end
end
