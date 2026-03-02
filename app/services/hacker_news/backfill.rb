# frozen_string_literal: true

require 'digest'

module HackerNews
  class Backfill
    BASE_URL = 'https://hn.algolia.com/api/v1/search_by_date'

    def call(before_timestamp: Time.zone.now.to_i)
      source = JobBoards::Source.find_or_create_by!(slug: 'hackernews', name: 'Hacker News')
      query = JobBoards::Query.find_or_create_by!(source_id: source.id)

      conn = Faraday.new(url: BASE_URL) do |f|
        f.params['tags'] = 'job'
        f.params['numericFilters'] = "created_at_i<#{before_timestamp}"
        f.params['hitsPerPage'] = 100
      end

      response = conn.get
      data = JSON.parse(response.body)

      data['hits'].each do |hit|
        signature = Digest::SHA256.hexdigest("hn-#{hit['objectID']}")
        
        JobBoards::Document.find_or_create_by!(signature:) do |doc|
          doc.source_id = source.id
          doc.job_boards_query_id = query.id
          # Transform Algolia format to match Firebase format as much as possible for the Syncer
          doc.document = {
            id: hit['objectID'],
            title: hit['title'],
            url: hit['url'],
            text: hit['comment_text'] || hit['story_text'],
            by: hit['author'],
            time: hit['created_at_i'],
            type: 'job'
          }.to_json
        end
      end
    end
  end
end
