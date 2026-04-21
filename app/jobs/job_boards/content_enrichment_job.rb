# frozen_string_literal: true

module JobBoards
  class ContentEnrichmentJob < ApplicationJob
    queue_as :default
    mediumweight!
    idempotent!

    def perform(limit: 50)
      return if SystemSetting.paused?

      # Find postings with missing bodies or pending enrichment
      targets = JobPosting.where(body: [nil, ""])
                          .where.not(status: "archived")
                          .where.not(target_url: [nil, ""])
                          .order(created_at: :desc)
                          .limit(limit)

      targets.each do |job|
        enrich_job(job)
        # Small sleep to prevent aggressive bot detection when doing batches
        sleep(rand(2..5))
      end
    end

    private

    def enrich_job(job)
      begin
        # 1. Resolve canonical URL (unwraps tracking links from emails)
        resolved_url = JobFetchers::UrlResolver.resolve(job.target_url)
        
        # 2. Use PageFetch to get the content
        fetch_result = JobFetchers::PageFetch.new(resolved_url).call
        return unless fetch_result

        # 3. Identify provider
        provider = detect_provider(fetch_result[:final_url])

        # 4. Extract content
        job_data = JobFetchers::CanonicalJobExtractor.new(fetch_result[:content], fetch_result[:final_url], provider).call
        
        if job_data[:description].present?
          # 5. Normalize and update
          markdown_body = ReverseMarkdown.convert(job_data[:description], unknown_tags: :bypass, github_flavored: true).strip
          
          job.update!(
            body: markdown_body,
            crawl_status: "enriched",
            enriched_at: Time.current,
            target_url: fetch_result[:final_url] # Update to canonical if resolved
          )
          
          # 6. Trigger background analysis
          JobBoards::Categorizer.new(job).call
          JobBoards::Embedder.new(job).call
          
          Rails.logger.info "[ContentEnrichment] Successfully enriched Job ##{job.id} (#{job.title})"
        else
          job.update!(crawl_status: 'enrichment_failed_no_content')
        end
      rescue => e
        job.update!(crawl_status: 'enrichment_error')
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
