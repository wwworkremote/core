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
        Rails.logger.info { "#{self.class.name}##{__method__} ==>> jobstory_id:#{jobstory_id}" }

        node_id += 1
        node_id = 1 if node_id > 5
        node = "node0#{node_id}"

        wait_until = i.seconds

        remote_fetch_jobstory(node, jobstory_id:, wait_until:)
      end
    end

    def remote_fetch_jobstory(node, jobstory_id:, wait_until:)
      api_endpoint = "http://#{node}"
      conn = Faraday.new(url: api_endpoint)

      response = conn.get do |req|
        req.url(api_endpoint)
        req.params['jobstory_id'] = jobstory_id
        req.params['wait_until'] = wait_until
      end

      if response.success?
        puts "Request was successful. Response body: #{response.body}"
      else
        puts "Request failed with status code #{response.status}"
      end
    end
  end
end
