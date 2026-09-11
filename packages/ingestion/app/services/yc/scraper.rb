# frozen_string_literal: true

require "nokogiri"

class Yc::Scraper
  include ApiGuard

  BASE_URL = "https://www.workatastartup.com/jobs"
  # workatastartup.com returns 406 Not Acceptable without an explicit Accept
  # header (bare Faraday/Ruby requests send none) -- TASK-11.
  REQUEST_HEADERS = {
    "Accept" => "text/html",
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  }.freeze

  def call(force: false)
    # `return` here escapes this method entirely (not just the block), since
    # with_api_guard discards the block's own return value -- scrape must
    # stay a pure predicate so this line is the only place `call` can
    # short-circuit to `false` on a failed fetch.
    with_api_guard("yc", cooldown: 4.hours, force:) { |source| return false unless scrape?(source) }
  end

  private

  def scrape?(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    response = fetch_response
    return false unless response

    jobs = extract_jobs(response.body)
    jobs ? persist_and_log?(source, query, jobs) : false
  end

  def fetch_response
    response = JobBoards::Client.new("yc").get(BASE_URL, {}, REQUEST_HEADERS)
    response if response && response.status == 200
  end

  def persist_and_log?(source, query, jobs)
    persist_jobs(source, query, jobs)
    Rails.logger.info "YC Scraper: Extracted #{jobs.count} jobs from embedded JSON."
    true
  end

  def extract_jobs(html)
    data_attr = Nokogiri::HTML(html).at_css("div[data-page]")&.[]("data-page")
    return nil unless data_attr

    JSON.parse(CGI.unescape_html(data_attr)).dig("props", "jobs") || []
  end

  def persist_jobs(source, query, jobs)
    jobs.each { |job_data| persist_job(source, query, job_data) }
  end

  def persist_job(source, query, job_data)
    JobBoards::Document.find_or_create_by!(signature: "yc-#{job_data['id']}") do |doc_record|
      doc_record.source_id = source.id
      doc_record.job_boards_query_id = query.id
      doc_record.document = job_document_attrs(job_data).to_json
    end
  end

  def job_document_attrs(job_data)
    { id: job_data["id"], title: job_data["title"], company: job_data["companyName"] }
      .merge(description: job_data["companyOneLiner"]) # Full desc requires sub-page fetch
      .merge(url: "https://www.workatastartup.com/jobs/#{job_data['id']}",
             location: job_data["location"], role_type: job_data["roleType"])
  end
end
