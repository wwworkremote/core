# frozen_string_literal: true

require 'nokogiri'

module Scraper
  module Glassdoor
    # Service to deep-scrape Glassdoor job listings and associated company intelligence.
    class ApiClient
      BASE_URL = 'https://www.glassdoor.com/Job/jobs.htm'

      def self.search(keywords, location: 'Remote')
        new.search(keywords, location)
      end

      def call
        search('Staff Ruby on Rails', 'Remote')
      end

      def search(keywords, location)
        source = JobBoards::Source.find_or_create_by!(slug: 'glassdoor') { |s| s.name = 'Glassdoor' }
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        { 'sc.keyword' => keywords, 'locT' => 'C', 'locId' => location }
        url = "https://www.glassdoor.com/Job/jobs.htm?suggestCount=0&suggestChosen=false&clickSource=searchBtn&typedKeyword=#{keywords}&locT=R&locId=110&jobType="

        Rails.logger.info "[Glassdoor::ApiClient] Fetching: #{url}"

        # Using Playwright for full page render
        fetch_result = JobFetchers::PageFetch.new(url).call
        return { success: false, error: 'Fetch failed' } unless fetch_result

        data = parse_results(fetch_result[:content])

        processed_count = 0
        data['results'].each do |job_data|
          # Create/Update Document
          signature = Digest::SHA256.hexdigest("glassdoor-#{job_data['external_id']}")
          doc = JobBoards::Document.find_or_initialize_by(signature: signature)
          doc.assign_attributes(
            source_id: source.id,
            job_boards_query_id: query.id,
            document: job_data.to_json,
            aasm_state: 'pending'
          )
          doc.save!
          processed_count += 1
        end

        { success: true, count: processed_count }
      end

      private

      def parse_results(html)
        doc = Nokogiri::HTML(html)
        results = []

        # Target the modern Glassdoor job card structure
        doc.css('li[data-test="jobListing"]').each do |card|
          external_id = card['data-id']
          next unless external_id

          results << {
            'jobTitle' => card.css('[data-test="job-title"]').text.strip,
            'companyName' => card.css('[data-test="employer-short-name"]').text.strip,
            'jobGeo' => card.css('[data-test="location"]').text.strip,
            'rating' => card.css('[data-test="rating"]').text.strip,
            'url' => "https://www.glassdoor.com#{card.css('a[data-test="job-link"]').first['href']}",
            'external_id' => external_id,
            'found_by_terms' => nil
          }
        end

        { 'results' => results }
      end
    end
  end
end
