# frozen_string_literal: true

module WeWorkRemotely
  class Feed
    attr_reader :client, :params, :path

    def initialize(client: nil, params: {}, path: 'remote-programming-jobs.rss')
      @client = client || WeWorkRemotely.client
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
