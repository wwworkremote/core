# frozen_string_literal: true

require 'nokogiri'

module Scraper
  module Dice
    # Service to scrape job listings from Dice.com.
    # Uses Playwright to handle client-side rendering and search parameters.
    class ApiClient
      BASE_URL = "https://www.dice.com/jobs"

      def self.search(keywords, location: 'Remote')
        new.search(keywords, location)
      end

      def call
        # Default search for Ruby/Rails roles
        search('Ruby on Rails', 'Remote')
      end

      def search(keywords, location)
        source = JobBoards::Source.find_or_create_by!(slug: 'dice') { |s| s.name = 'Dice' }
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        # Build the Dice search URL
        params = { q: keywords, l: location, countryCode: 'US', radius: 30, radiusUnit: 'mi', page: 1, pageSize: 20 }
        url = "#{BASE_URL}?#{params.to_query}"
        
        Rails.logger.info "[Dice::ApiClient] Fetching: #{url}"
        
        fetch_result = JobFetchers::PageFetch.new(url).call
        return { success: false, error: 'Fetch failed' } unless fetch_result

        data = parse_results(fetch_result[:content])
        
        processed_count = 0
        data['results'].each do |job_data|
          signature = Digest::SHA256.hexdigest("dice-#{job_data['external_id']}")
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

        # Target Dice's search result cards (d-job-card)
        doc.css('d-job-card, .card').each do |card|
          title_link = card.css('a.card-title-link').first
          next unless title_link

          job_id = title_link['id'] || title_link['href']&.match(%r{job-detail/([^/?]+)})&.[](1)
          next unless job_id

          results << {
            'jobTitle' => title_link.text.strip,
            'companyName' => card.css('[data-cy="search-result-company-name"], .card-company a').text.strip,
            'jobGeo' => card.css('.card-location').text.strip,
            'url' => title_link['href'].start_with?('http') ? title_link['href'] : "https://www.dice.com#{title_link['href']}",
            'external_id' => job_id,
            'found_by_terms' => nil
          }
        end

        { 'results' => results }
      end
    end
  end
end
