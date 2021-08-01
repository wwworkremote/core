# frozen_string_literal: true

module Monster
  class Feed
    attr_reader :client, :params, :path

    def initialize(client: nil, params: nil, path: nil, term: nil)
      @client = client || Monster.client
      @params = params || { q: term.presence || 'ruby' }
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
