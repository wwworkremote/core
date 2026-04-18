# frozen_string_literal: true

module Greenhouse
  class Fetcher
    include ApiGuard

    BASE_URL = 'https://boards-api.greenhouse.io/v1/boards'

    def call(force: false)
      with_api_guard('greenhouse', cooldown: 4.hours, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        boards = query.data['boards'] || %w[stripe airbnb github]
        terms = query.data['terms'] || ['']

        boards.each do |board|
          terms.each do |term|
            # Enqueue granular jobs instead of looping here
            JobBoards::GranularFetchJob.perform_later(self.class.name, board, term, source.id, query.id)
          end
        end
        true
      end
    rescue StandardError => e
      Rails.logger.error "Greenhouse Fetcher Error: #{e.message}"
      false
    end

    def fetch_granular(board, term, source_id, query_id)
      client = JobBoards::Client.new('greenhouse')
      url = "#{BASE_URL}/#{board}/jobs?content=true"
      
      response = client.get(url)
      return if response.nil? || response.status != 200

      data = Oj.load(response.body)
      jobs = data['jobs'] || []

      process_jobs(jobs, board, term, source_id, query_id)

      Rails.logger.info "Greenhouse: Fetched jobs for #{board} with term '#{term}'."
    end

    private

    def process_jobs(jobs, board, term, source_id, query_id)
      jobs.each do |job_data|
        next if term.present? && job_data['title'].downcase.exclude?(term.downcase)

        signature = "greenhouse-#{board}-#{job_data['id']}"
        doc = JobBoards::Document.find_or_initialize_by(signature: signature)
        doc.source_id = source_id
        doc.job_boards_query_id = query_id

        current_payload = doc.document.present? ? JSON.parse(doc.document) : job_data
        current_payload['found_by_terms'] ||= []
        current_payload['found_by_terms'] << term if term.present? && current_payload['found_by_terms'].exclude?(term)
        current_payload['board_slug'] = board

        doc.document = current_payload.to_json
        doc.save!
      end
    end
  end
end
