# frozen_string_literal: true

class Api::JobPostingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def enrich
    job_posting = JobPosting.find(params[:id])
    extracted   = params[:extracted]&.to_unsafe_h || {}
    provider    = params[:provider].presence || detect_provider(params[:url].to_s)

    # ── Description ─────────────────────────────────────────────────────────
    # Prefer the user-reviewed plain text from the extension panel; fall back
    # to re-running CanonicalJobExtractor on the raw HTML snapshot.
    markdown_body =
      if extracted["description_text"].present?
        source = extracted["description_html"].presence || extracted["description_text"]
        ReverseMarkdown.convert(source, unknown_tags: :bypass, github_flavored: true).strip
      else
        job_data = JobFetchers::CanonicalJobExtractor.new(
          params[:html], params[:url], provider
        ).call
        if job_data[:description].present?
          ReverseMarkdown.convert(job_data[:description], unknown_tags: :bypass,
                                                          github_flavored: true).strip
        end
      end

    if markdown_body.blank?
      return render json: { success: false, error: "No description found in captured content." },
                    status: :unprocessable_content
    end

    # ── Column-mapped fields ─────────────────────────────────────────────────
    attrs = {
      body: markdown_body,
      crawl_status: "enriched",
      enriched_at: Time.current
    }

    attrs[:title]        = extracted["title"]    if extracted["title"].present?
    attrs[:company]      = extracted["company"]  if extracted["company"].present?
    attrs[:location]     = extracted["location"] if extracted["location"].present?
    attrs[:target_url]   = extracted["apply_url"] if extracted["apply_url"].present?
    attrs[:published_at] = parse_date(extracted["posted_at"]) if extracted["posted_at"].present?

    if extracted["skills"].present?
      raw = extracted["skills"]
      attrs[:tags] = raw.is_a?(Array) ? raw : raw.split(/\s*,\s*/).map(&:strip).compact_blank
    end

    # ── JSONB data fields ────────────────────────────────────────────────────
    data_patch = {}
    %w[
      salary_min salary_max salary_currency salary_unit salary
      employment_type remote experience valid_through
      education qualifications responsibilities benefits
      company_logo_url industry
    ].each do |key|
      data_patch[key] = extracted[key] if extracted.key?(key) && extracted[key].present?
    end
    attrs[:data] = job_posting.data.merge(data_patch) if data_patch.any?

    job_posting.update!(attrs)

    # ── Background analysis ──────────────────────────────────────────────────
    JobBoards::Categorizer.new(job_posting).call
    JobBoards::Embedder.new(job_posting).call

    render json: { success: true, message: "Job ##{job_posting.id} enriched." }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "Job posting #{params[:id]} not found." }, status: :not_found
  end

  private

  # Use the provider string sent by the extension directly; only fall back to
  # URL detection for legacy callers that do not send the field.
  def detect_provider(url)
    url_lower = url.downcase
    if    url_lower.include?("linkedin.com")       then "linkedin"
    elsif url_lower.include?("indeed.com")         then "indeed"
    elsif url_lower.include?("adzuna.com")         then "adzuna"
    elsif url_lower.include?("greenhouse.io")      then "greenhouse"
    elsif url_lower.include?("lever.co")           then "lever"
    elsif url_lower.include?("workday.com") ||
          url_lower.include?("myworkdayjobs.com")  then "workday"
    elsif url_lower.include?("ashby.com") ||
          url_lower.include?("ashbyhq.com")        then "ashby"
    elsif url_lower.include?("smartrecruiters.com") then "smartrecruiters"
    elsif url_lower.include?("wellfound.com")      then "wellfound"
    elsif url_lower.include?("weworkremotely.com") then "weworkremotely"
    elsif url_lower.include?("remoteok.com")       then "remoteok"
    else "generic"
    end
  end

  def parse_date(val)
    return nil if val.blank?
    Time.zone.parse(val.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
