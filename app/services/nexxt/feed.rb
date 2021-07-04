# frozen_string_literal: true

module Nexxt
  class Feed
    attr_reader :client, :params, :path

    def initialize(client: nil, params: nil, path: nil)
      @client = client || Nexxt.client
      @params = params || { k: 'Ruby' }
      @path = path.to_s.strip
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
