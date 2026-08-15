# frozen_string_literal: true

# Direct-hiring-page adapter for companies whose career site runs on ADP's
# "myjobs.adp.com" platform (Follett Corporation among them) -- bypasses
# generic job boards entirely and reads structured requisition JSON straight
# from ADP's own API, the same shape of adapter Greenhouse::Fetcher and
# Lever::Fetcher are for their platforms. Session-token minting (Playwright)
# lives in Adp::TokenMinter; this class is the fetch/map flow only.
class Adp::Fetcher
  include ApiGuard

  CAREER_SITE_URL = "https://myjobs.adp.com"
  CONFIG_URL = "https://myjobs.adp.com/public/staffing/v1/career-site"
  REQUISITIONS_URL = "https://my.adp.com/myadp_prefix/mycareer/public/staffing/v1/job-requisitions/apply-custom-filters"
  SELECT_FIELDS = %w[reqId jobTitle publishedJobTitle jobDescription postingDate
                     clientRequisitionID requisitionLocations].join(",")
  PAGE_SIZE = 50

  def call(force: false)
    guarded_call(force)
  rescue StandardError => e
    Rails.logger.error "ADP Fetcher Error: #{e.message}"
    false
  end

  def fetch_granular(board, term, source_id, query_id)
    token = Adp::TokenMinter.call(board)
    return unless token

    context = build_context(board, term, source_id, query_id)
    fetch_pages(board, token, context)
  end

  private

  def guarded_call(force)
    with_api_guard("adp", cooldown: 4.hours, force: force) do |source|
      enqueue_granular_jobs(source)
      true
    end
  end

  def build_context(board, term, source_id, query_id)
    JobBoards::DocumentUpserter::Context.new(
      provider: "adp", slug: board, slug_key: "career_site", term: term,
      match_field: "jobTitle", source_id: source_id, query_id: query_id
    )
  end

  def enqueue_granular_jobs(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    boards(query).each { |board| terms(query).each { |term| enqueue_job(board, term, source, query) } }
  end

  # One slug per company career site -- add a new company by appending its
  # ADP career-site domain (the path segment right after myjobs.adp.com/) to
  # this BoardQuery's data["boards"], no code change required.
  def boards(query)
    query.data["boards"] || %w[corpfollettexternal]
  end

  def terms(query)
    query.data["terms"] || [""]
  end

  def enqueue_job(board, term, source, query)
    ids = { source_id: source.id, query_id: query.id }
    JobBoards::GranularFetchJob.perform_later(self.class.name, board, term, ids)
  end

  def career_site_client_name(board)
    response = JobBoards::Client.new("adp").get("#{CONFIG_URL}/#{board}")
    return board if response.nil? || response.status != 200

    Oj.load(response.body)["clientName"] || board
  end

  def fetch_pages(board, token, context)
    client_name = career_site_client_name(board)
    each_page(board, token) { |jobs| process_jobs(jobs, context, board, client_name) }
    Rails.logger.info "ADP: Fetched jobs for #{board}."
  end

  def each_page(board, token, &)
    skip = 0
    skip = process_page(board, token, skip, &) while skip
  end

  def process_page(board, token, skip, &)
    jobs = fetch_page(board, token, skip)
    return nil if jobs.blank?

    yield(jobs)
    jobs.count < PAGE_SIZE ? nil : skip + PAGE_SIZE
  end

  def fetch_page(_board, token, skip)
    response = JobBoards::Client.new("adp").get(REQUISITIONS_URL, requisition_params(skip), requisition_headers(token))
    return nil if response.nil? || response.status != 200

    Oj.load(response.body)["jobRequisitions"] || []
  end

  def requisition_params(skip)
    { "$orderby" => "postingDate desc", "$select" => SELECT_FIELDS, "$top" => PAGE_SIZE, "$skip" => skip,
      "tz" => "America/Chicago" }
  end

  def requisition_headers(token)
    { "Accept" => "application/json", "myjobstoken" => token, "referer" => "#{CAREER_SITE_URL}/" }
  end

  def process_jobs(jobs, context, board, client_name)
    jobs.each { |job_data| JobBoards::DocumentUpserter.call(context, enrich(job_data, board, client_name)) }
  end

  def enrich(job_data, board, client_name)
    job_data["id"] = job_data["reqId"]
    job_data["client_name"] = client_name
    job_data["target_url"] = "#{CAREER_SITE_URL}/#{board}/cx/job-details?reqId=#{job_data['reqId']}"
    job_data["location"] = location_text(job_data)
    job_data
  end

  def location_text(job_data)
    address = job_data.dig("requisitionLocations", 0, "address")
    return nil unless address

    [address["cityName"], address.dig("countrySubdivisionLevel1", "codeValue")].compact.join(", ")
  end
end
