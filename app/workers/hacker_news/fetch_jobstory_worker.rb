# frozen_string_literal: true

module HackerNews
  class FetchJobstoryWorker
    include Sidekiq::Worker
    include Sidekiq::Throttled::Worker

    sidekiq_throttle(concurrency: { limit: 4 }, threshold: { limit: 3, period: 2.seconds })

    sidekiq_options(queue: :hacker_news)

    def perform(jobstory_id)
      if HackerNews::V0::Jobstory.exists?(id: jobstory_id)
        Rails.logger.info { "jobstory_id: #{jobstory_id} | skip | #{Nodes.current} | #{Time.zone.now}" }
        return
      end

      Rails.logger.info { "jobstory_id: #{jobstory_id} | fetch | #{Nodes.current} | #{Time.zone.now}" }

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
