# frozen_string_literal: true

module Scraper
  class Enricher
    def self.call(job_posting)
      return unless job_posting.target_url.present?
      enrich_posting(job_posting)
    end

    def self.call_for_link(discovery_link)
      # 1. Check if we already have this job
      return if JobPosting.exists?(target_url: discovery_link.url)

      # 2. Use board-specific extraction (API-first if possible)
      case discovery_link.board_name.downcase
      when 'cord' then extract_cord_job(discovery_link)
      else
        # Fallback to standard enrichment (browsing)
        extract_generic_job(discovery_link)
      end
    end

    private

    def self.extract_cord_job(discovery_link)
      listing_id = discovery_link.url.match(/jobs\/(\d+)/)&.[](1)
      return extract_generic_job(discovery_link) unless listing_id

      api_url = "https://cord.com/api/v2/public/position/#{listing_id}"
      response = Faraday.get(api_url)
      
      if response.success?
        json = JSON.parse(response.body)
        data = json['data']
        
        JobPosting.create!(
          title: data['position'],
          company: data['companyName'],
          target_url: discovery_link.url,
          body: data['jobDescription'],
          location: data['locationCity'],
          status: 'none',
          crawl_status: 'enriched',
          enriched_at: Time.current,
          signature: Digest::SHA256.hexdigest("cord-#{listing_id}")
        )
        discovery_link.update!(status: 'processed')
      else
        extract_generic_job(discovery_link)
      end
    end

    def self.extract_generic_job(discovery_link)
      # Create stub first or just fetch and create
      fetch_result = JobFetchers::PageFetch.new(discovery_link.url).call
      return unless fetch_result

      extractor = JobFetchers::CanonicalJobExtractor.new(fetch_result[:content], fetch_result[:final_url], discovery_link.board_name)
      data = extractor.call

      JobPosting.create!(
        title: data[:title],
        company: data[:company],
        target_url: discovery_link.url,
        body: data[:body],
        location: data[:location],
        status: 'none',
        crawl_status: 'enriched',
        enriched_at: Time.current,
        signature: Digest::SHA256.hexdigest("#{discovery_link.board_name}-#{discovery_link.url}")
      )
      discovery_link.update!(status: 'processed')
    end

    def self.enrich_posting(job_posting)
      fetch_result = JobFetchers::PageFetch.new(job_posting.target_url).call
      return unless fetch_result

      extractor = JobFetchers::CanonicalJobExtractor.new(fetch_result[:content], fetch_result[:final_url], job_posting.source&.name || 'manual')
      data = extractor.call

      job_posting.update!(
        body: data[:body] || job_posting.body,
        enriched_at: Time.current,
        crawl_status: 'enriched'
      )
    end
  end
end
