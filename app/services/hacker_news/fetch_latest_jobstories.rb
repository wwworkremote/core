# frozen_string_literal: true

module HackerNews
  class FetchLatestJobstories
    def call
      conn ||= HackerNews.client

      jobstory_ids = Oj.load(get_jobstories(conn:).body, symbolize_names: true)

      FetchJobstories.new(jobstory_ids:).call(conn:)
    end

    def get_jobstories(conn:)
      conn.get('/v0/jobstories.json')
    end
  end
end
