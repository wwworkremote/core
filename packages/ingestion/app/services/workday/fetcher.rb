# frozen_string_literal: true

# Direct-hiring-page adapter for companies whose career site runs on Workday
# (the dominant ATS at large regulated enterprises -- financial services,
# healthcare, insurance -- the exact company profile this account's target
# roles come from). Same shape as Greenhouse::Fetcher/Lever::Fetcher/
# Adp::Fetcher: Query#data["boards"] lists companies, one GranularFetchJob
# per company, results flow through the existing Document -> Syncer ->
# JobPosting pipeline.
#
# Unlike Adp::Fetcher, Workday's public "CXS" job-search API needs no
# session token at all -- plain unauthenticated JSON over HTTP, verified
# live against a real tenant. A board is {"tenant", "wd", "site"} (the three
# path segments Workday's own career-site URL is built from, e.g.
# https://myhrhome.wd1.myworkdayjobs.com/OneMainCareers ->
# {"tenant"=>"myhrhome","wd"=>"wd1","site"=>"OneMainCareers"}).
class Workday::Fetcher
  include ApiGuard

  PAGE_SIZE = 20

  def call(force: false)
    guarded_call(force)
  rescue StandardError => e
    Rails.logger.error "Workday Fetcher Error: #{e.message}"
    false
  end

  def fetch_granular(board, term, source_id, query_id)
    context = build_context(board, term, source_id, query_id)
    each_page(board, term) { |postings| process_postings(postings, board, context) }
    Rails.logger.info "Workday: Fetched jobs for #{board['tenant']}/#{board['site']}."
  end

  private

  def guarded_call(force)
    with_api_guard("workday", cooldown: 4.hours, force: force) do |source|
      enqueue_granular_jobs(source)
      true
    end
  end

  def build_context(board, _term, source_id, query_id)
    JobBoards::DocumentUpserter::Context.new(
      provider: "workday", slug: "#{board['tenant']}/#{board['site']}", slug_key: "career_site",
      term: "", match_field: "title", source_id: source_id, query_id: query_id
    )
  end

  def enqueue_granular_jobs(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    boards(query).each { |board| terms(query).each { |term| enqueue_job(board, term, source, query) } }
  end

  # One entry per company career site -- add a company by appending its
  # {tenant, wd, site} triple (read off its own career-site URL) to this
  # BoardQuery's data["boards"], no code change required.
  def boards(query)
    query.data["boards"] || [{ "tenant" => "myhrhome", "wd" => "wd1", "site" => "OneMainCareers" }]
  end

  def terms(query)
    query.data["terms"] || [""]
  end

  def enqueue_job(board, term, source, query)
    ids = { source_id: source.id, query_id: query.id }
    JobBoards::GranularFetchJob.perform_later(self.class.name, board, term, ids)
  end

  def base_url(board)
    "https://#{board['tenant']}.#{board['wd']}.myworkdayjobs.com"
  end

  def list_url(board)
    "#{base_url(board)}/wday/cxs/#{board['tenant']}/#{board['site']}/jobs"
  end

  def detail_url(board, external_path)
    "#{base_url(board)}/wday/cxs/#{board['tenant']}/#{board['site']}#{external_path}"
  end

  def each_page(board, term, &)
    offset = 0
    offset = process_page(board, term, offset, &) while offset
  end

  def process_page(board, term, offset, &)
    postings = fetch_page(board, term, offset)
    return nil if postings.blank?

    yield(postings)
    postings.count < PAGE_SIZE ? nil : offset + PAGE_SIZE
  end

  def fetch_page(board, term, offset)
    response = post_search(board, search_body(term, offset))
    return nil if response.nil? || response.status != 200

    Oj.load(response.body)["jobPostings"] || []
  end

  def search_body(term, offset)
    { appliedFacets: {}, limit: PAGE_SIZE, offset: offset, searchText: term }.to_json
  end

  def post_search(board, body)
    JobBoards::Client.new("workday").post(list_url(board), body, { "Content-Type" => "application/json" })
  end

  def process_postings(postings, board, context)
    postings.each do |posting|
      detail = fetch_detail(board, posting["externalPath"])
      next unless detail

      JobBoards::DocumentUpserter.call(context, detail)
    end
  end

  def fetch_detail(board, external_path)
    response = JobBoards::Client.new("workday").get(detail_url(board, external_path))
    return nil if response.nil? || response.status != 200

    enrich(Oj.load(response.body), board, external_path)
  end

  def enrich(payload, board, external_path)
    info = payload["jobPostingInfo"] || {}
    { "id" => info["jobPostingId"] || external_path, "title" => info["title"],
      "jobDescription" => info["jobDescription"], "location" => info["location"],
      "employment_type" => info["timeType"], "target_url" => info["externalUrl"],
      "company" => payload.dig("hiringOrganization", "name") || board["tenant"] }
  end
end
