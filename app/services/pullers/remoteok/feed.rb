# frozen_string_literal: true

module Pullers
  module RemoteOK
    class Feed
      attr_reader :client, :params, :path

      def initialize(client: nil, params: nil, path: nil)
        @client = client || RemoteOK.client
        @params = params || {}
        @path = path || 'remote-dev-jobs.rss'
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
