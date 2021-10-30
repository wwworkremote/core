# frozen_string_literal: true

module Pullers
  module AuthenticJobs
    class Feed
      attr_reader :client, :params, :path

      def initialize(client: nil, params: nil, path: nil, term: nil)
        @client = client || AuthenticJobs.client

        @params = (params || {
          feed: 'job_feed',
          job_types: %w[freelance full-time internship part-time].join(','),
          search_location: 'remote',
          job_categories: 'back-end-engineering',
          search_keywords: term.presence || 'ruby'
        }).compact_blank

        @path = path.to_s.strip
      end

      def call
        request
        self
      end

      def request
        ap [path, params]
        @request ||= client.get(path, params)
      end

      def data
        @data ||= request.body
      end
    end
  end
end

# https://authenticjobs.com/?feed=job_feed
# &job_types=freelance%2Cfull-time%2Cinternship%2Cpart-time
# &search_location=remote
# &job_categories=back-end-engineering
# &search_keywords=ruby
