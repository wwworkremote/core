# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

require 'typhoeus/adapters/faraday'

module HackerNews
  module V0
    module Item
      class Jobs
        attr_reader :job_ids

        def initialize(job_ids)
          @job_ids = job_ids
        end

        def call
          jobs
        end

        def jobs
          @jobs ||= job_ids.map do |job_id|
            faraday.get("#{job_id}.json")
          end
        end

        def faraday
          @faraday ||= Faraday.new do |f|
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
end
