# frozen_string_literal: true

require "reverse_markdown"

# Maps a provider's raw JSON payload onto a JobPosting's attributes -- split
# out of JobBoards::Syncer to keep the sync-flow class itself under
# Metrics/ClassLength; mapping provider JSON is a genuinely separate concern
# from shielding/saving/enriching a JobPosting.
#
# ClassLength itself is disabled here rather than split further: this class
# is already one cohesive responsibility (map provider JSON -> JobPosting),
# and it's a flat table of 14 near-identical provider mappers -- scattering
# those across 14 files would make "what does every provider map?" strictly
# harder to answer for zero real decoupling benefit.
# rubocop:disable-next Metrics/ClassLength
class JobBoards::Syncer::AttributeMapper
  PROVIDER_MAPPERS = {
    "hackernews" => :map_hackernews,
    "arbeitnow" => :map_arbeitnow,
    "adzuna" => :map_adzuna,
    "remotive" => :map_remotive,
    "wwr" => :map_wwr,
    "remoteok" => :map_remoteok,
    "jobicy" => :map_jobicy,
    "rubyonrails" => :map_rubyonrails,
    "greenhouse" => :map_greenhouse,
    "lever" => :map_lever,
    "adp" => :map_adp,
    "workday" => :map_workday,
    "yc" => :map_yc,
    "indeed" => :map_scraped_html,
    "linkedin" => :map_scraped_html,
    "glassdoor" => :map_scraped_html,
    "dice" => :map_scraped_html
  }.freeze

  # Every provider's raw payload already lands in job_posting.data verbatim
  # (see finalize_body) -- the employment-type signal just sits under a
  # different key per provider instead of the canonical "employment_type"
  # the extension/JSON-LD capture path already writes. Normalizing it here
  # means the browse filter and any future backfill both key off one field
  # regardless of source, and existing employment_type values (extension
  # captures) are never clobbered.
  EMPLOYMENT_TYPE_EXTRACTORS = {
    "adzuna" => ->(data) { data["contract_time"] || data["contract_type"] },
    "lever" => ->(data) { data.dig("categories", "commitment") },
    "arbeitnow" => ->(data) { Array(data["job_types"]).first },
    "jobicy" => ->(data) { Array(data["jobType"]).first },
    "remotive" => ->(data) { data["job_type"] }
  }.freeze

  def self.call(job_posting, data, slug)
    new.call(job_posting, data, slug)
  end

  def call(job_posting, data, slug)
    mapper = slug.match?(/^email/) ? :map_email : PROVIDER_MAPPERS.fetch(slug, :map_generic)
    send(mapper, job_posting, data)
    normalize_employment_type(data, slug)
    finalize_body(job_posting, data)
  end

  private

  def normalize_employment_type(data, slug)
    return if data["employment_type"].present?

    extractor = EMPLOYMENT_TYPE_EXTRACTORS[slug]
    value = extractor&.call(data)
    data["employment_type"] = value if value.present?
  end

  def finalize_body(job_posting, data)
    # Preserve intersection data in the JobPosting payload
    job_posting.data = data.merge("found_by_terms" => data["found_by_terms"])

    # ONLY normalize and set body if we actually have one.
    # This prevents overwriting an enriched body with nil during a re-sync.
    new_body = normalize_body(job_posting.body)
    job_posting.body = new_body if new_body.present?
  end

  # Each mapper below is a flat field-transcription table for one provider's
  # JSON shape -- already the simplest possible form. Further mechanical
  # splitting would fragment readable, atomic assignment lines into
  # meaningless fragments; a declarative field-table (like
  # CanonicalJobExtractor's Selectors) was considered and rejected here
  # because fields don't share a uniform present?-guard policy (title/body/
  # target_url mostly guard against overwriting with blank, company/
  # location/tags mostly don't) -- encoding that per-field would add more
  # complexity than it removes, for a mechanical mapping with no real logic.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def map_hackernews(job_posting, data)
    job_posting.title        = data["title"] if data["title"].present?
    job_posting.body         = data["text"] if data["text"].present?
    job_posting.target_url   = data["url"] if data["url"].present?
    job_posting.published_at = Time.zone.at(data["time"]) if data["time"]
  end

  def map_arbeitnow(job_posting, data)
    job_posting.title        = data["title"] if data["title"].present?
    job_posting.body         = data["description"] if data["description"].present?
    job_posting.target_url   = data["url"] if data["url"].present?
    job_posting.published_at = Time.zone.at(data["created_at"]) if data["created_at"]
    job_posting.company      = data["company_name"]
    job_posting.location     = data["location"]
    job_posting.tags         = data["tags"]
  end

  def map_adzuna(job_posting, data)
    job_posting.title        = data["title"] if data["title"].present?
    job_posting.body         = data["description"] if data["description"].present?
    job_posting.target_url   = data["redirect_url"] if data["redirect_url"].present?
    job_posting.published_at = Time.zone.parse(data["created"]) if data["created"]
    job_posting.company      = data.dig("company", "display_name")
    job_posting.location     = data.dig("location", "display_name")
  end

  def map_remotive(job_posting, data)
    job_posting.title        = data["title"] if data["title"].present?
    job_posting.body         = data["description"] if data["description"].present?
    job_posting.target_url   = data["url"] if data["url"].present?
    job_posting.published_at = Time.zone.parse(data["publication_date"]) if data["publication_date"]
    job_posting.company      = data["company_name"]
    job_posting.location     = data["candidate_required_location"]
  end

  def map_wwr(job_posting, data)
    job_posting.title        = data["title"] if data["title"].present?
    job_posting.body         = data["content"] || data["summary"] if (data["content"] || data["summary"]).present?
    job_posting.target_url   = data["url"] if data["url"].present?
    job_posting.published_at = Time.zone.parse(data["published"]) if data["published"]
    job_posting.company      = parse_wwr_company(data["title"]) if data["title"]
  end

  def map_remoteok(job_posting, data)
    job_posting.title        = data["position"] if data["position"].present?
    job_posting.body         = data["description"] if data["description"].present?
    job_posting.target_url   = data["url"] if data["url"].present?
    job_posting.published_at = Time.zone.at(data["date"].to_i) if data["date"]
    job_posting.company      = data["company"]
    job_posting.location     = data["location"]
    job_posting.tags         = data["tags"]
  end

  def map_jobicy(job_posting, data)
    job_posting.title        = data["jobTitle"] if data["jobTitle"].present?
    job_posting.body         = data["jobDescription"] if data["jobDescription"].present?
    job_posting.target_url   = data["url"] if data["url"].present?
    job_posting.published_at = parse_time_or_now(data["pubDate"])
    job_posting.company      = data["companyName"]
    job_posting.location     = data["jobGeo"]
  end

  # jobs.rubyonrails.org's RSS titles are "{Role}[, remote] at {Company}" --
  # no separate structured company field exists (confirmed live 2026-08-19),
  # same "title-suffix" shape as WeWorkRemotely/Greenhouse's logo-alt
  # fallback in the extension. No location field either -- left unset rather
  # than guessed from free text.
  def map_rubyonrails(job_posting, data)
    title = data["title"]
    job_posting.title        = rails_job_title(title) if title.present?
    job_posting.body         = data["description"] if data["description"].present?
    job_posting.target_url   = data["link"] if data["link"].present?
    job_posting.published_at = parse_time_or_now(data["pub_date"])
    job_posting.company      = rails_job_company(title) if title.present?
  end

  def map_greenhouse(job_posting, data)
    job_posting.title        = data["title"] if data["title"].present?
    job_posting.body         = data["content"] if data["content"].present?
    job_posting.target_url   = data["absolute_url"] if data["absolute_url"].present?
    job_posting.published_at = parse_time_or_now(data["updated_at"])
    job_posting.company      = data["company_name"]
    job_posting.location     = data.dig("location", "name")
  end

  def map_lever(job_posting, data)
    job_posting.title        = data["text"] if data["text"].present?
    job_posting.body         = data["description"] if data["description"].present?
    job_posting.target_url   = data["hostedUrl"] if data["hostedUrl"].present?
    job_posting.published_at = (Time.zone.at(data["createdAt"] / 1000) rescue Time.zone.now)
    job_posting.company      = data["site_slug"]&.capitalize
    job_posting.location     = data.dig("categories", "location")
    job_posting.tags         = Array(data.dig("categories", "team"))
  end

  def map_adp(job_posting, data)
    title = data["publishedJobTitle"] || data["jobTitle"]
    job_posting.title        = title if title.present?
    job_posting.body         = data["jobDescription"] if data["jobDescription"].present?
    job_posting.target_url   = data["target_url"] if data["target_url"].present?
    job_posting.published_at = parse_time_or_now(data["postingDate"])
    job_posting.company      = data["client_name"]
    job_posting.location     = data["location"]
  end

  def map_workday(job_posting, data)
    job_posting.title        = data["title"] if data["title"].present?
    job_posting.body         = data["jobDescription"] if data["jobDescription"].present?
    job_posting.target_url   = data["target_url"] if data["target_url"].present?
    job_posting.published_at = Time.zone.now
    job_posting.company      = data["company"]
    job_posting.location     = data["location"]
  end

  def map_yc(job_posting, data)
    job_posting.title        = data["title"] if data["title"].present?
    job_posting.body         = data["description"] if data["description"].present?
    job_posting.target_url   = data["url"] if data["url"].present?
    job_posting.published_at = Time.zone.now
    job_posting.company      = data["company"]
    job_posting.location     = data["location"]
    job_posting.tags         = Array(data["role_type"])
  end

  def map_email(job_posting, data)
    job_posting.title        = data["title"] if data["title"].present?
    job_posting.body         = data["description"] if data["description"].present?
    job_posting.target_url = data["canonical_url"] || data["url"] if (data["canonical_url"] || data["url"]).present?
    job_posting.published_at = parse_time_or_now(data["email_received_at"])
    job_posting.company      = data["company"]
    job_posting.location     = data["location"]
  end

  def map_scraped_html(job_posting, data)
    job_posting.title      = data["jobTitle"] || data["title"] if (data["jobTitle"] || data["title"]).present?
    job_posting.company    = data["companyName"] || data["company"]
    job_posting.location   = data["jobGeo"] || data["location"]
    job_posting.target_url = data["url"] || data["target_url"]
  end

  # Generic mapper for any source not covered above.
  def map_generic(job_posting, data)
    title = data["title"] || data["job_title"] || data["position"]
    job_posting.title = title if title.present?
    body = data["description"] || data["body"] || data["content"]
    job_posting.body = body if body.present?
    url = data["url"] || data["link"] || data["target_url"] || data["redirect_url"]
    job_posting.target_url = url if url.present?
    job_posting.company  = data["company"] || data["company_name"] || data["employer"]
    job_posting.location = data["location"] || data["job_location"] || data["geo"]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def parse_time_or_now(value)
    return Time.zone.now if value.blank?

    Time.zone.parse(value) || Time.zone.now
  rescue StandardError
    Time.zone.now
  end

  def normalize_body(html)
    return nil if html.blank?

    # Convert HTML to Markdown
    ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true).strip
  end

  def parse_wwr_company(title)
    # WWR titles are often "Company Name: Job Title"
    title.split(":").first.strip
  end

  def rails_job_title(title)
    title.sub(/\s+at\s+[^,]+\z/, "").strip
  end

  def rails_job_company(title)
    title.split(/\s+at\s+/).last&.strip
  end
end
