# frozen_string_literal: true

module Monster
  class Feed
    attr_reader :client, :params

    def initialize(client: nil, params: nil)
      @client = client || Monster.client
      @params = params || { q: 'Ruby-on-Rails' }
    end

    def call
      request
      self
    end

    def request
      @request ||= client.get('', params)
    end

    def data
      @data ||= request.body
    end
  end
end
