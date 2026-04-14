# frozen_string_literal: true

module HackerNews
  class FetchLatestJobstories
    include ApiGuard

    def call(force: false)
      with_api_guard('hackernews', cooldown: 15.minutes, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)
        conn ||= Faraday.new(
          url: 'https://hacker-news.firebaseio.com',
          headers: { 'Content-Type' => 'application/json' }
        )

        jobstory_ids = Oj.load(conn.get('/v0/jobstories.json').body, symbolize_names: true)

        Rails.logger.info { "#{self.class.name}##{__method__} ==>> jobstory_ids:#{jobstory_ids.join(',')}" }

        FetchJobstories.new(jobstory_ids: jobstory_ids, source_id: source.id, query_id: query.id).call
      end
    end
  end
end
