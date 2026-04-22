# frozen_string_literal: true

require 'nokogiri'

module Scraper
  module Indeed
    class ApiClient
      # Indeed uses a more complex URL structure for search
      BASE_URL = 'https://www.indeed.com/jobs'

      def self.search(query, location: 'Remote')
        new.search(query, location)
      end

      def call
        # Default search if called without arguments via DataAcquisitionManager
        search('Staff Engineer', 'Remote')
      end

      def search(query_text, location)
        source = JobBoards::Source.find_by(slug: 'indeed')
        query = JobBoards::Query.find_by(source_id: source&.id)

        params = {
          q: query_text,
          l: location,
          from: 'searchOnHP'
        }

        url = "#{BASE_URL}?#{params.to_query}"
        Rails.logger.info "[Indeed::ApiClient] Fetching: #{url}"

        fetch_result = JobFetchers::PageFetch.new(url).call
        return { success: false, error: 'Fetch failed' } unless fetch_result

        data = parse_results(fetch_result[:content])

        processed_count = 0
        data['results'].each do |job_data|
          signature = Digest::SHA256.hexdigest("indeed-#{job_data['external_id']}")
          doc = JobBoards::Document.find_or_initialize_by(signature: signature)
          next unless doc.new_record?
          doc.source_id = source&.id
          doc.job_boards_query_id = query&.id
          doc.document = job_data.to_json
          doc.save!
          processed_count += 1
        end

        { success: true, count: processed_count }
      end

      private

      def parse_results(html)
        doc = Nokogiri::HTML(html)
        results = []

        doc.css('div.job_seen_beacon').each do |card|
          parsed_card = parse_card(card)
          results << parsed_card if parsed_card
        end

        { 'results' => results }
      end

      def parse_card(card)
        title_link = card.css('h2.jobTitle a').first
        return nil unless title_link

        job_key = title_link['data-jk']
        {
          'jobTitle' => title_link.text.strip,
          'companyName' => card.css('span[data-testid="company-name"]').text.strip,
          'jobGeo' => card.css('div[data-testid="text-location"]').text.strip,
          'url' => "https://www.indeed.com/viewjob?jk=#{job_key}",
          'external_id' => job_key,
          'found_by_terms' => nil
        }
      end
    end
  end
end
