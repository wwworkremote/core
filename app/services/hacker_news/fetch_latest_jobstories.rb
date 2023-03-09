# frozen_string_literal: true

module HackerNews
  class FetchLatestJobstories
    def call
      conn ||= Faraday.new(
        url: 'https://hacker-news.firebaseio.com',
        headers: { 'Content-Type' => 'application/json' }
      )

      jobstory_ids = Oj.load(conn.get('/v0/jobstories.json').body, symbolize_names: true)

      Rails.logger.info { "#{self.class.name}##{__method__} ==>> jobstory_ids:#{jobstory_ids.join(',')}" }

      FetchJobstories.new(jobstory_ids:).call
    end
  end
end
