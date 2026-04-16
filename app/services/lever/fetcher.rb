# frozen_string_literal: true

module Lever
  class Fetcher
    include ApiGuard

    BASE_URL = 'https://api.lever.co/v0/postings'

    def call(force: false)
      with_api_guard('lever', cooldown: 4.hours, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        # List of sites to fetch (tuned via Query data)
        sites = query.data['sites'] || ['gitlab', 'netflix', 'palantir']

        sites.each do |site|
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
              signature = "lever-#{site}-#{job_data['id']}"

              JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
                doc.source_id = source.id
                doc.job_boards_query_id = query.id
                # Inject site for context
                job_data['site_slug'] = site
                doc.document = job_data.to_json
              end
            end

            Rails.logger.info "Lever: Fetched #{jobs.count} jobs for #{site} (skip: #{skip})."
            break if jobs.count < limit
            skip += limit
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
