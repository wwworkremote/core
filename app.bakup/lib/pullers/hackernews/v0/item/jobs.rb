# frozen_string_literal: true

module Pullers
  module HackerNews
    module V0
      module Item
        class Jobs
          attr_reader :job_ids, :client

          def initialize(job_ids:, client: nil)
            @job_ids = job_ids
            @client = client || HackerNews.client
          end

          def call
            request
            self
          end

          def request
            @request ||= job_ids.map do |job_id|
              Job.new(job_id:, client:).call.data
            end
          end

          def data
            @data ||= request
          end
        end
      end
    end
  end
end
