# frozen_string_literal: true

module HackerNews
  class FetchJobstoryWorker
    include Sidekiq::Worker
    include Sidekiq::Throttled::Worker

    sidekiq_throttle(concurrency: { limit: 3 }, threshold: { limit: 9, period: 1.minute })

    sidekiq_options(queue: :hacker_news)

    def perform(jobstory_id)
      Rails.logger.info { "jobstory_id: #{jobstory_id} | #{Nodes.current} | #{Time.zone.now}" }

      conn ||= Faraday.new(
        url: 'https://hacker-news.firebaseio.com',
        headers: { 'Content-Type' => 'application/json' }
      )

      jobstory = Oj.load(conn.get("/v0/item/#{jobstory_id}.json").body, symbolize_names: true)

      return unless jobstory[:type] == 'job'

      attrs = jobstory.slice(:by, :score, :time, :title, :url, :text).merge(data: jobstory)

      HackerNews::V0::Jobstory.create_with(**attrs).find_or_create_by(id: jobstory_id)
    end
  end
end
