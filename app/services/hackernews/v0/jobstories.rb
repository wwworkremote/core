# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

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
          f.headers[:user_agent] = "OutlierJobs::HackerNews/1.0 (#{self.class.name};#{Rails.env})"

          f.url_prefix = 'https://hacker-news.firebaseio.com'
          f.path_prefix = 'v0'

          f.headers[:accept] = 'application/json; charset=utf-8'

          f.response :json, content_type: /\bjson$/
          f.response :follow_redirects

          f.adapter :typhoeus
        end
      end
    end
  end
end
