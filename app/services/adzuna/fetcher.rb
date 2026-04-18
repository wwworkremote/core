# frozen_string_literal: true

require 'digest'

module Adzuna
  class Fetcher
    include ApiGuard
    BASE_URL = 'https://api.adzuna.com/v1/api/jobs/us/search/1'

    def call(force: false)
      app_id = ENV.fetch('ADZUNA_APPLICATION_ID', nil)
      app_key = ENV.fetch('ADZUNA_APPLICATION_KEY', nil)

      unless app_id && app_key
        Rails.logger.error 'Adzuna API credentials missing.'
        return false
      end

      with_api_guard('adzuna', cooldown: 4.hours, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        client = JobBoards::Client.new('adzuna')
        params = {
          app_id: app_id,
          app_key: app_key,
          what: 'remote',
          'content-type': 'application/json'
        }

        response = client.get(BASE_URL, params)
        return false if response.nil? || response.status != 200

        data = JSON.parse(response.body)

        unless data['results']
          puts "Adzuna API Error: #{response.body}"
          return
        end

        data['results'].each do |job|
          signature = Digest::SHA256.hexdigest("adzuna-#{job['id']}")

          JobBoards::Document.find_or_create_by!(signature:) do |doc|
            doc.source_id = source.id
            doc.job_boards_query_id = query.id
            doc.document = job.to_json
          end
        end
      end
    end
  end
end
