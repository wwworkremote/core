# frozen_string_literal: true

module Api
  class JobPostingsController < ApplicationController
    skip_before_action :verify_authenticity_token
    
    def enrich
      job_posting = JobPosting.find(params[:id])
      html = params[:html]
      url = params[:url]

      # Use existing infrastructure to extract and normalize
      # 1. Identify provider
      provider = detect_provider(url)
      
      # 2. Extract description and metadata
      job_data = JobFetchers::CanonicalJobExtractor.new(html, url, provider).call
      
      if job_data[:description].present?
        # 3. Convert to Markdown
        markdown_body = ReverseMarkdown.convert(job_data[:description], unknown_tags: :bypass, github_flavored: true).strip
        
        # 4. Update the job posting
        job_posting.update!(
          body: markdown_body,
          crawl_status: 'enriched',
          enriched_at: Time.current
        )

        # 5. Trigger background analysis (categorization + embedding)
        JobBoards::Categorizer.new(job_posting).call
        JobBoards::Embedder.new(job_posting).call

        render json: { success: true, message: "Job enriched and queued for analysis." }
      else
        render json: { success: false, error: "No description found in captured content." }, status: :unprocessable_entity
      end
    end

    private

    def detect_provider(url)
      url_lower = url.downcase
      if url_lower.include?('linkedin.com') then 'linkedin'
      elsif url_lower.include?('indeed.com') then 'indeed'
      elsif url_lower.include?('adzuna.com') then 'adzuna'
      else 'generic'
      end
    end
  end
end
