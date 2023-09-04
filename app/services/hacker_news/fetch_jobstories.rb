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

      jobstory_ids.each_with_index do |jobstory_id, i|
        node_id += 1
        node_id = 1 if node_id > 5
        node = "node0#{node_id}"

        wait_until = i.seconds

        remote_fetch_jobstory(node, jobstory_id:, wait_until:)
      end
    end

    def remote_fetch_jobstory(node, jobstory_id:, wait_until:)
      Rails.logger.info { "#{self.class.name}##{__method__} ==>> node:#{node}, jobstory_id:#{jobstory_id}, wait_until:#{wait_until}" }

      api_endpoint = "http://#{node}/hacker_news/fetch_jobstory"

      conn = Faraday.new(url: api_endpoint) do |faraday|
        faraday.request(:json)
        faraday.response(:json, content_type: /\bjson$/)
        faraday.adapter(Faraday.default_adapter)
      end

      request_json = Oj.dump({ jobstory_id:, wait_until: })

      response = conn.put do |req|
        req.url(api_endpoint)
        req.headers['Content-Type'] = 'application/json'
        req.body = request_json
      end

      ap response.body
    end
  end
end
