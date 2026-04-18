# frozen_string_literal: true

module HackerNews
  class FetchJobstories
    attr_reader :jobstory_ids, :source_id, :query_id

    def initialize(jobstory_ids:, source_id: nil, query_id: nil)
      @jobstory_ids = jobstory_ids
      @source_id = source_id
      @query_id = query_id
    end

    def call
      jobstory_ids.each do |jobstory_id|
        # Spread the load over 5 minutes to be a good API citizen
        HackerNews::FetchJobstoryJob.set(wait: rand(1..300).seconds).perform_later(jobstory_id, source_id, query_id)
      end

      Rails.logger.info "Enqueued #{jobstory_ids.count} jobstories for fetching with randomized delays."
    end
  end
end
