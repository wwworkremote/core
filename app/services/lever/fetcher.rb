# frozen_string_literal: true

module Lever
  class Fetcher
    include ApiGuard

    BASE_URL = 'https://api.lever.co/v0/postings'

    def call(force: false)
      with_api_guard('lever', cooldown: 4.hours, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        # List of sites and terms (tuned via Query data)
        sites = query.data['sites'] || %w[gitlab netflix palantir]
        terms = query.data['terms'] || ['']

        sites.each do |site|
          terms.each do |term|
            # Lever pagination: skip/limit
            limit = 100
            skip = 0

            loop do
              url = "#{BASE_URL}/#{site}?mode=json&limit=#{limit}&skip=#{skip}"
              response = Faraday.get(url)
              break unless response.success?

              jobs = Oj.load(response.body)
              break if jobs.empty?

              jobs.each do |job_data|
                # Case-insensitive term filtering
                next if term.present? && job_data['text'].downcase.exclude?(term.downcase)

                signature = "lever-#{site}-#{job_data['id']}"

                doc = JobBoards::Document.find_or_initialize_by(signature: signature)
                doc.source_id = source.id
                doc.job_boards_query_id = query.id

                # Track which terms found this job
                current_payload = doc.document.present? ? JSON.parse(doc.document) : job_data
                current_payload['found_by_terms'] ||= []
                current_payload['found_by_terms'] << term if term.present? && current_payload['found_by_terms'].exclude?(term)
                current_payload['site_slug'] = site

                doc.document = current_payload.to_json
                doc.save!
              end

              Rails.logger.info "Lever: Fetched jobs for #{site} with term '#{term}' (skip: #{skip})."
              break if jobs.count < limit
              skip += limit
            end
          end
        end
        true
      end
    rescue StandardError => e
      Rails.logger.error "Lever Fetcher Error: #{e.message}"
      false
    end
  end
end
