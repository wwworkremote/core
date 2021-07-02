# frozen_string_literal: true

module StackOverflow
  module Jobs
    class Feed
      attr_reader :client, :params

      def initialize(client: nil, params: nil)
        @client = client || StackOverflow.client
        @params = params || { q: 'ruby on rails', sort: 'p', r: true }
      end

      def call
        request
        self
      end

      def request
        @request ||= client.get('feed', params)
      end

      def data
        @data ||= request.body
      end
    end
  end
end
