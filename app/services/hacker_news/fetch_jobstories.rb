# frozen_string_literal: true

require 'hacker_news'

module HackerNews
  class FetchJobstories
    attr_reader :jobstory_ids

    def initialize(jobstory_ids:)
      @jobstory_ids = jobstory_ids
    end

    def call
      node_id = 0

      jobstory_ids.each_with_index do |jobstory_id, wait_for|
        node_id += 1
        node_id = 0 if node_id > 5
        node = "node0#{node_id}"

        remote_fetch_jobstory(node, jobstory_id:, wait_for:)
      end
    end

    def remote_fetch_jobstory(node, jobstory_id:, wait_for:)
      Rails.logger.info { "#{self.class.name}##{__method__} ==>> node:#{node}, jobstory_id:#{jobstory_id}, wait_for:#{wait_for}" }

      api_endpoint = "http://#{node}/hacker_news/fetch_jobstory"

      conn = Faraday.new(url: api_endpoint) do |faraday|
        faraday.request(:json)
        faraday.response(:json, content_type: /\bjson$/)
        faraday.adapter(Faraday.default_adapter)
      end

      request_body = {
        'jobstory_id' => jobstory_id,
        'wait_for' => wait_for
      }

      request_json = Oj.dump(request_body)

      response = conn.put do |req|
        req.url(api_endpoint)
        req.headers['Content-Type'] = 'application/json'
        req.body = request_json
      end

      ap response.body
    end
  end
end
