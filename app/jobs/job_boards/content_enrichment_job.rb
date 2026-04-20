# frozen_string_literal: true

module JobBoards
  class ContentEnrichmentJob < ApplicationJob
    queue_as :default

    def perform(limit: 50)
      # Find postings with missing bodies that haven't been archived
      targets = JobPosting.where(body: [nil, ""])
                          .where.not(status: "archived")
                          .where.not(target_url: [nil, ""])
                          .order(created_at: :desc)
                          .limit(limit)

      targets.each do |job|
        enrich_job(job)
      end
    end

    private

    def enrich_job(job)
      begin
        # Use PageFetch to get the content
        fetch_result = JobFetchers::PageFetch.new(job.target_url).call
        return unless fetch_result

        # Identify provider from URL if not available via source
        provider = detect_provider(job)

        # Extract content
        job_data = JobFetchers::CanonicalJobExtractor.new(fetch_result[:content], fetch_result[:final_url], provider).call
        
        if job_data[:description].present?
          # Normalize and update
          markdown_body = ReverseMarkdown.convert(job_data[:description], unknown_tags: :bypass, github_flavored: true).strip
          
          job.update!(
            body: markdown_body,
            crawl_status: "enriched",
            enriched_at: Time.current
          )
          
          # Trigger categorization and embedding now that we have content
          JobBoards::Categorizer.new(job).call
          JobBoards::Embedder.new(job).call
          
          Rails.logger.info "[ContentEnrichment] Successfully enriched Job ##{job.id} (#{job.title})"
        end
      rescue => e
        Rails.logger.error "[ContentEnrichment] Failed for Job ##{job.id}: #{e.message}"
      end
    end

    def detect_provider(job)
      url = job.target_url.downcase
      if url.include?("linkedin.com")
        "linkedin"
      elsif url.include?("indeed.com")
        "indeed"
      elsif url.include?("adzuna.com")
        "adzuna"
      else
        "generic"
      end
    end
  end
end
