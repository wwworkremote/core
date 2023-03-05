# frozen_string_literal: true

module HackerNews
  class FetchBackfillJobstories
    attr_reader :offset, :limit

    def initialize(offset: 1, limit: 200)
      @offset = offset
      @limit = limit
    end

    def call
      conn ||= HackerNews.client

      maxitemid = HackerNews.min_jobstory_id - offset
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

