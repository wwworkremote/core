# frozen_string_literal: true

class Greenhouse::Fetcher
  include ApiGuard

  BASE_URL = "https://boards-api.greenhouse.io/v1/boards"

  def call(force: false)
    guarded_call(force)
  rescue StandardError => e
    Rails.logger.error "Greenhouse Fetcher Error: #{e.message}"
    false
  end

  def fetch_granular(board, term, source_id, query_id)
    jobs = fetch_jobs(board)
    return if jobs.nil?

    process_jobs(jobs, build_context(board, term, source_id, query_id))
    Rails.logger.info "Greenhouse: Fetched jobs for #{board} with term '#{term}'."
  end

  private

  def guarded_call(force)
    with_api_guard("greenhouse", cooldown: 4.hours, force: force) do |source|
      enqueue_granular_jobs(source)
      true
    end
  end

  def fetch_jobs(board)
    response = JobBoards::Client.new("greenhouse").get("#{BASE_URL}/#{board}/jobs?content=true")
    return nil if response.nil? || response.status != 200

    Oj.load(response.body)["jobs"] || []
  end

  def build_context(board, term, source_id, query_id)
    JobBoards::DocumentUpserter::Context.new(
      provider: "greenhouse", slug: board, slug_key: "board_slug", term: term,
      match_field: "title", source_id: source_id, query_id: query_id
    )
  end

  def enqueue_granular_jobs(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    boards(query).each { |board| terms(query).each { |term| enqueue_job(board, term, source, query) } }
  end

  def boards(query)
    query.data["boards"] || %w[stripe airbnb github]
  end

  def terms(query)
    query.data["terms"] || [""]
  end

  def enqueue_job(board, term, source, query)
    JobBoards::GranularFetchJob.perform_later(self.class.name, board, term, source.id, query.id)
  end

  def process_jobs(jobs, context)
    jobs.each { |job_data| JobBoards::DocumentUpserter.call(context, job_data) }
  end
end
