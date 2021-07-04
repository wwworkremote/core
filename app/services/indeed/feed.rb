# frozen_string_literal: true

module Indeed
  class Feed
    attr_reader :client, :params, :path

    DEFAULT_PARAMS = {
      remotejob: '032b3046-06a3-4876-8dfd-474eb5e7ed11',
      jlid: 'aaa2b906602aa8f5',
      rbl: 'Remote',
      l: 'Remote',
      q: 'Ruby'
    }.freeze

    def initialize(client: nil, params: DEFAULT_PARAMS, path: '')
      @client = client || Indeed.client
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
