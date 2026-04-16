# frozen_string_literal: true

module Greenhouse
  class Fetcher
    include ApiGuard

    BASE_URL = 'https://boards-api.greenhouse.io/v1/boards'

    def call(force: false)
      with_api_guard('greenhouse', cooldown: 4.hours, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        # List of boards to fetch (tuned via Query data)
        boards = query.data['boards'] || ['stripe', 'airbnb', 'github']

        boards.each do |board|
          url = "#{BASE_URL}/#{board}/jobs?content=true"
          response = Faraday.get(url)
          next unless response.success?

          data = Oj.load(response.body)
          jobs = data['jobs'] || []

          jobs.each do |job_data|
            signature = "greenhouse-#{board}-#{job_data['id']}"

            JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
              doc.source_id = source.id
              doc.job_boards_query_id = query.id
              # Inject board name for context
              job_data['board_slug'] = board
              doc.document = job_data.to_json
            end
          end

          Rails.logger.info "Greenhouse: Fetched #{jobs.count} jobs for #{board}."
        end
        true
      end
    rescue StandardError => e
      Rails.logger.error "Greenhouse Fetcher Error: #{e.message}"
      false
    end
  end
end
