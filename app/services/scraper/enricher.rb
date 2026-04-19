# frozen_string_literal: true

module Scraper
  class Enricher
    def self.call(job_posting)
      return unless job_posting.target_url.present?

      fetch_result = JobFetchers::PageFetch.new(job_posting.target_url, mode: :playwright).call
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
