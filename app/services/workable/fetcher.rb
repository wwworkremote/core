# frozen_string_literal: true

require 'digest'

module Workable
  class Fetcher
    def initialize(subdomain:, token:)
      @subdomain = subdomain
      @token = token
    end

    def call
      source = JobBoards::Source.find_or_create_by!(slug: 'workable', name: 'Workable')
      query = JobBoards::Query.find_or_create_by!(source_id: source.id)

      url = "https://#{@subdomain}.workable.com/spi/v3/jobs"

      conn = Faraday.new(url:) do |f|
        f.headers['Authorization'] = "Bearer #{@token}"
        f.params['state'] = 'published'
      end

      response = conn.get
      data = JSON.parse(response.body)

      unless data['jobs']
        puts "Workable API Error: #{response.body}"
        return
      end

      data['jobs'].each do |job|
        signature = Digest::SHA256.hexdigest("workable-#{@subdomain}-#{job['shortcode']}")

        JobBoards::Document.find_or_create_by!(signature:) do |doc|
          doc.source_id = source.id
          doc.job_boards_query_id = query.id
          doc.document = job.to_json
        end
      end
    end
  end
end
