# frozen_string_literal: true

module Pullers
  module HackerNews
    module_function

    def pull(*)
      jobstories = V0::Jobstories.new.call

      service = V0::Item::Jobs.new(
        job_ids: jobstories.data,
        client: jobstories.client
      )

      service.call

      service.data
    end

    def client
      Faraday.new do |f|
        f.request :retry, max: 3, interval: 0.05, interval_randomness: 0.5, backoff_factor: 3, max_interval: 900

        f.headers[:user_agent] = 'WwworkRemote::HackerNews/1.0'

        f.url_prefix = 'https://hacker-news.firebaseio.com'
        f.path_prefix = 'v0'

        f.headers[:accept] = 'application/json; charset=utf-8'

        f.use :instrumentation
        f.response :json, content_type: /\bjson$/
        f.response :encoding
      end
    end
  end
end
