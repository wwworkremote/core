# frozen_string_literal: true

require 'digest'

module Arbeitnow
  class Fetcher
    API_URL = 'https://www.arbeitnow.com/api/job-board-api'

    def call
      source = JobBoards::Source.find_or_create_by!(slug: 'arbeitnow', name: 'Arbeitnow')
      query = JobBoards::Query.find_or_create_by!(source_id: source.id)

      response = Faraday.get(API_URL)
      data = JSON.parse(response.body)

      data['data'].each do |job|
        signature = Digest::SHA256.hexdigest("arbeitnow-#{job['slug']}")
        
        JobBoards::Document.find_or_create_by!(signature:) do |doc|
          doc.source_id = source.id
          doc.job_boards_query_id = query.id
          doc.document = job.to_json
        end
      end
    end
  end
end
