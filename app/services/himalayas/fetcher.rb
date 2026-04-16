# frozen_string_literal: true

module Himalayas
  class Fetcher
    include ApiGuard

    API_URL = 'https://himalayas.app/jobs/api'

    def call(force: false)
      with_api_guard('himalayas', cooldown: 1.hour, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        response = Faraday.get(API_URL)
        unless response.success?
          puts "Himalayas API Error: #{response.status} - #{response.body}"
          return false
        end

        data = Oj.load(response.body)
        jobs = data['jobs'] || []

        jobs.each do |job_data|
          # Use a stable signature for idempotency
          signature = "himalayas-#{job_data['id']}"

          JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
            doc.source_id = source.id
            doc.job_boards_query_id = query.id
            doc.document = job_data.to_json
          end
        end

        Rails.logger.info "Himalayas: Fetched #{jobs.count} jobs."
        true
      end
    end
  end
end
