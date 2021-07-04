# frozen_string_literal: true

module Nexxt
  class Feed
    attr_reader :client, :params, :path

    def initialize(client: nil, params: { k: 'Ruby' }, path: '')
      @client = client || Nexxt.client
      @params = params
      @path = path
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
