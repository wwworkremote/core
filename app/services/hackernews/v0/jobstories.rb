# frozen_string_literal: true

# frozen_string_literal

require 'faraday'
require 'faraday_middleware'
# require 'faraday/encoding'

require 'typhoeus/adapters/faraday'

module HackerNews
  module V0
    class Jobstories
      def call
        jobstories
      end

      def jobstories
        @jobstories ||= faraday.get('jobstories.json')
      end

      def faraday
        Faraday.new do |f|
          f.headers[:user_agent] = 'OutlierJobs::HackerNews/1.0'

          f.url_prefix = 'https://hacker-news.firebaseio.com'
          f.path_prefix = 'v0'

          f.headers[:accept] = 'application/json; charset=utf-8'

          f.response :json, content_type: /\bjson$/
          # f.response :encoding
          f.response :follow_redirects

          # f.response :logger, nil, { headers: true, bodies: true }

          # f.use :instrumentation

          f.adapter :typhoeus
        end
      end
    end
  end
end
