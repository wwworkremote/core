# frozen_string_literal: true

module HackerNews
  class FetchJobstories
    attr_reader :jobstory_ids

    def initialize(jobstory_ids:)
      @jobstory_ids = jobstory_ids
    end

    def call
      jobstory_ids.each do |jobstory_id|
        # Spread the load over 5 minutes to be a good API citizen
        HackerNews::FetchJobstoryWorker.perform_in(rand(1..300).seconds, jobstory_id)
      end

      Rails.logger.info "Enqueued #{jobstory_ids.count} jobstories for fetching with randomized delays."
    end
  end
end
