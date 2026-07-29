# frozen_string_literal: true

class JobBoards::ContentEnrichmentJob < ApplicationJob
  queue_as :light
  mediumweight!
  idempotent!

  def perform(limit: 50)
    return if SystemSetting.paused?

    pending_targets(limit).each { |job| process(job) }
  end

  private

  def pending_targets(limit)
    JobPosting.where(body: [nil, ""])
              .where.not(status: %w[archived expired])
              .where.not(target_url: [nil, ""])
              .order(created_at: :desc)
              .limit(limit)
  end

  def process(job)
    check_cancellation!
    enrich_job(job)
    # Small sleep to prevent aggressive bot detection when doing batches
    sleep(rand(2..5))
  end

  def enrich_job(job)
    fetch_result = fetch_content(job)
    return unless fetch_result

    apply_extraction(job, fetch_result)
  rescue StandardError => e
    handle_error(job, e)
  end

  def fetch_content(job)
    resolved_url = JobFetchers::UrlResolver.resolve(job.target_url)
    JobFetchers::PageFetch.new(resolved_url).call
  end

  def apply_extraction(job, fetch_result)
    provider = JobFetchers::ProviderDetector.call(fetch_result[:final_url])
    job_data = JobFetchers::CanonicalJobExtractor.new(fetch_result[:content], fetch_result[:final_url], provider).call
    handle_job_data(job, job_data, fetch_result)
  end

  def handle_job_data(job, job_data, fetch_result)
    return job.update!(crawl_status: "enrichment_blocked") if job_data.nil?
    return job.update!(crawl_status: "enrichment_failed_no_content") if job_data[:description].blank?

    finalize_enrichment(job, job_data, fetch_result)
  end

  def finalize_enrichment(job, job_data, fetch_result)
    update_job_content(job, job_data, fetch_result)
    trigger_analysis(job)
    Rails.logger.info "[ContentEnrichment] Successfully enriched Job ##{job.id} (#{job.title})"
  end

  def update_job_content(job, job_data, fetch_result)
    job.update!(enriched_attributes(job_data, fetch_result))
  end

  def enriched_attributes(job_data, fetch_result)
    { body: to_markdown(job_data[:description]), crawl_status: "enriched" }
      .merge(enriched_at: Time.current, target_url: fetch_result[:final_url])
  end

  def to_markdown(description)
    ReverseMarkdown.convert(description, unknown_tags: :bypass, github_flavored: true).strip
  end

  def trigger_analysis(job)
    JobBoards::Categorizer.new(job).call
    JobBoards::Embedder.new(job).call
  end

  def handle_error(job, error)
    job.update!(crawl_status: "enrichment_error")
    Rails.logger.error "[ContentEnrichment] Failed for Job ##{job.id}: #{error.message}"
  end
end
