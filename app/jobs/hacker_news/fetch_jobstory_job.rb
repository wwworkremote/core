# frozen_string_literal: true

module HackerNews
  class FetchJobstoryJob < ApplicationJob
    include ApiGuard
    queue_as :default

    def perform(jobstory_id, source_id = nil, query_id = nil)
      return if source_locked?('hackernews')

      client = JobBoards::Client.new('hackernews')
      url = "https://hacker-news.firebaseio.com/v0/item/#{jobstory_id}.json"

      response = client.get(url)
      return if response.nil? || response.status != 200

      data = Oj.load(response.body, symbolize_names: true)
      return unless data && data[:type] == 'job'

      source_id ||= JobBoards::Source.find_by(slug: 'hackernews')&.id
      query_id ||= JobBoards::Query.find_by(source_id: source_id)&.id

      return unless source_id && query_id

      signature = Digest::SHA256.hexdigest("hn-#{jobstory_id}")

      JobBoards::Document.create_or_find_by!(signature: signature) do |doc|
        doc.source_id = source_id
        doc.job_boards_query_id = query_id
        doc.document = data.to_json
      end

      # Trigger sync after fetch
      JobBoards::Syncer.new.call
    end
  end
end
