# frozen_string_literal: true

module HackerNews
  class FetchJobstoryWorker
    include Sidekiq::Worker

    sidekiq_options(queue: :hacker_news)

    def perform(jobstory_id, source_id = nil, query_id = nil)
      signature = Digest::SHA256.hexdigest("hn-#{jobstory_id}")
      if JobBoards::Document.exists?(signature: signature)
        Rails.logger.info { "jobstory_id: #{jobstory_id} | skip | #{Nodes.current} | #{Time.zone.now}" }
        return
      end

      Rails.logger.info { "jobstory_id: #{jobstory_id} | fetch | #{Nodes.current} | #{Time.zone.now}" }

      conn ||= Faraday.new(
        url: 'https://hacker-news.firebaseio.com',
        headers: { 'Content-Type' => 'application/json' }
      )

      response = conn.get("/v0/item/#{jobstory_id}.json")
      return unless response.success?

      jobstory = Oj.load(response.body, symbolize_names: true)

      return unless jobstory[:type] == 'job'

      JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
        doc.source_id = source_id
        doc.job_boards_query_id = query_id
        doc.document = jobstory.to_json
      end
    end
  end
end
