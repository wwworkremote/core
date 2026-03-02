# frozen_string_literal: true

require 'digest'

module Remotive
  class Fetcher
    API_URL = 'https://remotive.com/api/remote-jobs'

    def call
      source = JobBoards::Source.find_or_create_by!(slug: 'remotive', name: 'Remotive')
      query = JobBoards::Query.find_or_create_by!(source_id: source.id)

      response = Faraday.get(API_URL)
      data = JSON.parse(response.body)

      data['jobs'].each do |job|
        signature = Digest::SHA256.hexdigest("remotive-#{job['id']}")
        
        JobBoards::Document.find_or_create_by!(signature:) do |doc|
          doc.source_id = source.id
          doc.job_boards_query_id = query.id
          doc.document = job.to_json
        end
      end
    end
  end
end
