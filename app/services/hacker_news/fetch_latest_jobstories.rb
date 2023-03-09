# frozen_string_literal: true

module HackerNews
  class FetchLatestJobstories
    def call
      conn ||= Faraday.new(
        url: 'https://hacker-news.firebaseio.com',
        headers: { 'Content-Type' => 'application/json' }
      )

      jobstory_ids = Oj.load(get_jobstories(conn:).body, symbolize_names: true)

      FetchJobstories.new(jobstory_ids:).call
    end

    def get_jobstories(conn:)
      conn.get('/v0/jobstories.json')
    end
  end
end
