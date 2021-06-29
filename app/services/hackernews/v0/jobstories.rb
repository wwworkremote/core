# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

require 'typhoeus/adapters/faraday'
# require 'faraday/http_cache'

# service = HackerNews::V0::Jobstories.new
# service.call
# jobstories = service.jobstories

module HackerNews
  module V0
    class Jobstories
      def call
        request
        self
      end

      def jobstories
        @jobstories ||= request.body
      end

      def request
        @request ||= client.get('jobstories.json')
      end

      def client
        @client ||= Faraday.new do |f|
          # f.use :http_cache, logger: ActiveSupport::Logger.new(STDOUT)
          # f.use :http_cache, store: Rails.cache, logger: ActiveSupport::Logger.new(STDOUT), serializer: Marshal

          f.headers[:user_agent] = "OutlierJobs::HackerNews/1.0 (#{self.class.name};#{Rails.env})"

          f.url_prefix = 'https://hacker-news.firebaseio.com'
          f.path_prefix = 'v0'

          f.headers[:accept] = 'application/json; charset=utf-8'

          f.response :json, content_type: /\bjson$/
          f.response :encoding
          f.response :follow_redirects

          f.adapter :typhoeus
        end
      end
    end
  end
end
