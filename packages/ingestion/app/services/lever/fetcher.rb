# frozen_string_literal: true

class Lever::Fetcher
  include ApiGuard

  BASE_URL = "https://api.lever.co/v0/postings"
  PAGE_SIZE = 100

  def call(force: false)
    guarded_call(force)
  rescue StandardError => e
    Rails.logger.error "Lever Fetcher Error: #{e.message}"
    false
  end

  def fetch_granular(site, term, source_id, query_id)
    context = build_context(site, term, source_id, query_id)
    each_page(site, term) { |jobs| process_jobs(jobs, context) }
  end

  private

  def guarded_call(force)
    with_api_guard("lever", cooldown: 4.hours, force: force) do |source|
      enqueue_granular_jobs(source)
      true
    end
  end

  def build_context(site, term, source_id, query_id)
    JobBoards::DocumentUpserter::Context.new(
      provider: "lever", slug: site, slug_key: "site_slug", term: term,
      match_field: "text", source_id: source_id, query_id: query_id
    )
  end

  def enqueue_granular_jobs(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    sites(query).each { |site| terms(query).each { |term| enqueue_job(site, term, source, query) } }
  end

  def sites(query)
    query.data["sites"] || %w[gitlab netflix palantir]
  end

  def terms(query)
    query.data["terms"] || [""]
  end

  def enqueue_job(site, term, source, query)
    JobBoards::GranularFetchJob.perform_later(self.class.name, site, term, { source_id: source.id, query_id: query.id })
  end

  def each_page(site, term, &)
    skip = 0
    skip = process_page(site, term, skip, &) while skip
  end

  def process_page(site, term, skip, &)
    jobs = fetch_page(site, skip)
    return nil if jobs.blank?

    yield(jobs)
    log_page(site, term, skip)
    jobs.count < PAGE_SIZE ? nil : skip + PAGE_SIZE
  end

  def fetch_page(site, skip)
    response = JobBoards::Client.new("lever").get(page_url(site, skip))
    return nil if response.nil? || response.status != 200

    Oj.load(response.body)
  end

  def log_page(site, term, skip)
    Rails.logger.info "Lever: Fetched jobs for #{site} with term '#{term}' (skip: #{skip})."
  end

  def page_url(site, skip)
    "#{BASE_URL}/#{site}?mode=json&limit=#{PAGE_SIZE}&skip=#{skip}"
  end

  def process_jobs(jobs, context)
    jobs.each { |job_data| JobBoards::DocumentUpserter.call(context, job_data) }
  end
end
