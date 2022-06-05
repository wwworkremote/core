# frozen_string_literal: true

module Pullers
  module HackerNews
    module V0
      module Item
        class Job
          attr_reader :job_id, :client

          def initialize(job_id:, client: nil)
            @job_id = job_id
            @client = client || HackerNews.client
          end

          def call
            request
            self
          end

          def request
            @request ||= client.get("item/#{job_id}.json")
          end

          def data
            @data ||= request.body
          end
        end
      end
    end
  end
end
