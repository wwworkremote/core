# frozen_string_literal: true

module HackerNews
  module V0
    class Jobstories
      attr_reader :client

      def initialize(client: nil)
        @client = client || HackerNews.client
      end

      def call
        request
        self
      end

      def request
        @request ||= client.get('jobstories.json')
      end

      def data
        @data ||= request.body
      end
    end
  end
end
