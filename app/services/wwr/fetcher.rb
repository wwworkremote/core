# frozen_string_literal: true

require 'digest'
require 'feedjira'

module Wwr
  class Fetcher
    include ApiGuard
    RSS_URL = 'https://weworkremotely.com/remote-jobs.rss'

    def call(force: false)
      with_api_guard('wwr', cooldown: 30.minutes, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        xml = Faraday.get(RSS_URL).body
        feed = Feedjira.parse(xml)

        feed.entries.each do |entry|
          signature = Digest::SHA256.hexdigest("wwr-#{entry.entry_id}")
          
          JobBoards::Document.find_or_create_by!(signature:) do |doc|
            doc.source_id = source.id
            doc.job_boards_query_id = query.id
            doc.document = {
              title: entry.title,
              url: entry.url,
              entry_id: entry.entry_id,
              published: entry.published,
              content: entry.content,
              summary: entry.summary
            }.to_json
          end
        end
      end
    end
  end
end
