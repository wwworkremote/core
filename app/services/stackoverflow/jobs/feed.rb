# frozen_string_literal: true

module StackOverflow
  module Jobs
    class Feed
      attr_reader :client, :params, :path

      def initialize(client: nil, params: nil, path: nil)
        @client = client || StackOverflow.client
        @params = params || { q: 'ruby', sort: 'p', r: true }
        @path = path || 'feed'
      end

      def call
        request
        self
      end

      def request
        @request ||= client.get(path, params)
      end

      def data
        @data ||= request.body
      end
    end
  end
end
