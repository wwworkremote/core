# frozen_string_literal: true

class HackerNews::FetchJobstories
  attr_reader :jobstory_ids, :source_id, :query_id

  def initialize(jobstory_ids:, source_id: nil, query_id: nil)
    @jobstory_ids = jobstory_ids
    @source_id = source_id
    @query_id = query_id
  end

  def call
    jobstory_ids.each { |jobstory_id| enqueue(jobstory_id) }
    Rails.logger.info "Enqueued #{jobstory_ids.count} jobstories for fetching with randomized delays."
  end

  private

  # Spread the load over 5 minutes to be a good API citizen
  def enqueue(jobstory_id)
    HackerNews::FetchJobstoryJob.set(wait: rand(1..300).seconds).perform_later(jobstory_id, source_id, query_id)
  end
end
