# frozen_string_literal: true

module HackerNews
  class FetchBackfillJobstories
    attr_reader :offset, :limit

    def initialize(offset: 1, limit: 200)
      @offset = offset
      @limit = limit
    end

    def call
      conn ||= Faraday.new(
        url: 'https://hacker-news.firebaseio.com',
        headers: { 'Content-Type' => 'application/json' }
      )

      maxitemid = HackerNews::V0::Jobstory.minimum(:id)
      minitemid = maxitemid - limit

      jobstory_ids = (minitemid..maxitemid).to_a

      ap jobstory_ids.minmax

      FetchJobstories.new(jobstory_ids:).call(conn:)
    end

    def get_jobstories(conn:)
      conn.get('/v0/jobstories.json')
    end
  end
end

