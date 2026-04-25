# frozen_string_literal: true

require "reverse_markdown"

class JobBoards::Syncer
  def call(limit: 10)
    processed_count = 0
    sources_to_update = Set.new
    pending_docs = JobBoards::Document.where(aasm_state: ["pending", nil]).limit(limit)
    Rails.logger.info "[Syncer] Found #{pending_docs.count} pending documents (limited to #{limit})"

    pending_docs.find_each do |doc|
      Rails.logger.info "[Syncer] Processing document #{doc.id} (signature: #{doc.signature[0..8]}...)"
      if sync_document(doc)
        processed_count += 1
        sources_to_update << doc.source_id
      end
    end

    # Update last_ingested_at for all sources that brought in new data
    sources_to_update.each do |source_id|
      JobBoards::Source.find(source_id).update!(last_ingested_at: Time.current)
    end

    processed_count
  rescue ActiveRecord::ConnectionTimeoutError => e
    Rails.logger.error "[Syncer] Database connection pool exhausted: #{e.message}. Halting sync."
    0
  end

  private

  def sync_document(doc)
    source = JobBoards::Source.find(doc.source_id)
    data = JSON.parse(doc.document)

    origin = Origin.find_or_create_by!(name: source.name)
    # Ensure the dashboard Source has a name for telemetry/UI visibility
    dashboard_source = ::Source.find_or_create_by!(signature: "#{source.slug}-default") do |s|
      s.origin = origin
      s.name = source.name # jsonb_accessor will put this in the event field
    end

    # Use a transaction and rescue uniqueness errors for high-concurrency safety
    begin
      job_posting = JobPosting.find_or_initialize_by(signature: doc.signature)

      # Shield: If user has manually purged this, do not reactivate it
      if job_posting.status == "purged"
        doc.update!(aasm_state: "processed")
        return true
      end

      job_posting.source_id = dashboard_source.id
      map_attributes(job_posting, data, source.slug)

      # Resolve Company and check if ingestion is enabled
      company_name = job_posting.company_name
      if company_name.present?
        company = Company.find_or_create_by!(name: company_name) do |c|
          c.slug = company_name.parameterize
        end
        job_posting.company_id = company.id

        # Mark as ignored if company has ingestion disabled
        job_posting.ignore unless company.ingestion_enabled?
      end

      # Apply Quality Filter
      job_posting.ignore unless JobBoards::QualityFilter.new(job_posting).useful?

      # Capture the result of save! in a way that handles race conditions
      if job_posting.save
        # Transition document state
        if doc.respond_to?(:processed!)
          doc.processed!
        else
          doc.update!(aasm_state: "processed", updated_at: Time.current)
        end

        # Only categorize if not already enriched/categorized AND not ignored
        if !job_posting.ignored? && job_posting.data["ai_category"].blank?
          JobBoards::Categorizer.new(job_posting).call
          JobBoards::Embedder.new(job_posting).call
        end
        true
      else
        # If it failed validation but it was a uniqueness error on signature,
        # we might have lost a race, but the data is there, so mark doc as processed.
        if job_posting.errors[:signature].include?("has already been taken")
          doc.update!(aasm_state: "processed")
          return true
        end
        Rails.logger.error "[Syncer] Validation failed for Job signature #{doc.signature}: " \
                           "#{job_posting.errors.full_messages.join(', ')}"
        false
      end
    rescue ActiveRecord::RecordNotUnique
      # Extreme race condition: another thread created it between find and save
      doc.update!(aasm_state: "processed")
      true
    rescue StandardError => e
      Rails.logger.error "[Syncer] Unexpected error syncing document #{doc.id}: #{e.message}"
      false
    end
  end

  def map_attributes(job_posting, data, slug)
    case slug
    when "hackernews"
      job_posting.title        = data["title"] if data["title"].present?
      job_posting.body         = data["text"] if data["text"].present?
      job_posting.target_url   = data["url"] if data["url"].present?
      job_posting.published_at = Time.zone.at(data["time"]) if data["time"]
    when "arbeitnow"
      job_posting.title        = data["title"] if data["title"].present?
      job_posting.body         = data["description"] if data["description"].present?
      job_posting.target_url   = data["url"] if data["url"].present?
      job_posting.published_at = Time.zone.at(data["created_at"]) if data["created_at"]
      job_posting.company      = data["company_name"]
      job_posting.location     = data["location"]
      job_posting.tags         = data["tags"]
    when "adzuna"
      job_posting.title        = data["title"] if data["title"].present?
      job_posting.body         = data["description"] if data["description"].present?
      job_posting.target_url   = data["redirect_url"] if data["redirect_url"].present?
      job_posting.published_at = Time.zone.parse(data["created"]) if data["created"]
      job_posting.company      = data.dig("company", "display_name")
      job_posting.location     = data.dig("location", "display_name")
    when "remotive"
      job_posting.title        = data["title"] if data["title"].present?
      job_posting.body         = data["description"] if data["description"].present?
      job_posting.target_url   = data["url"] if data["url"].present?
      job_posting.published_at = Time.zone.parse(data["publication_date"]) if data["publication_date"]
      job_posting.company      = data["company_name"]
      job_posting.location     = data["candidate_required_location"]
    when "wwr"
      job_posting.title        = data["title"] if data["title"].present?
      job_posting.body         = data["content"] || data["summary"] if (data["content"] || data["summary"]).present?
      job_posting.target_url   = data["url"] if data["url"].present?
      job_posting.published_at = Time.zone.parse(data["published"]) if data["published"]
      job_posting.company      = parse_wwr_company(data["title"]) if data["title"]
    when "remoteok"
      job_posting.title        = data["position"] if data["position"].present?
      job_posting.body         = data["description"] if data["description"].present?
      job_posting.target_url   = data["url"] if data["url"].present?
      job_posting.published_at = Time.zone.at(data["date"].to_i) if data["date"]
      job_posting.company      = data["company"]
      job_posting.location     = data["location"]
      job_posting.tags         = data["tags"]
    when "jobicy"
      job_posting.title        = data["jobTitle"] if data["jobTitle"].present?
      job_posting.body         = data["jobDescription"] if data["jobDescription"].present?
      job_posting.target_url   = data["url"] if data["url"].present?
      job_posting.published_at = (Time.zone.parse(data["pubDate"]) rescue Time.zone.now)
      job_posting.company      = data["companyName"]
      job_posting.location     = data["jobGeo"]
    when "greenhouse"
      job_posting.title        = data["title"] if data["title"].present?
      job_posting.body         = data["content"] if data["content"].present?
      job_posting.target_url   = data["absolute_url"] if data["absolute_url"].present?
      job_posting.published_at = (Time.zone.parse(data["updated_at"]) rescue Time.zone.now)
      job_posting.company      = data["company_name"]
      job_posting.location     = data.dig("location", "name")
    when "lever"
      job_posting.title        = data["text"] if data["text"].present?
      job_posting.body         = data["description"] if data["description"].present?
      job_posting.target_url   = data["hostedUrl"] if data["hostedUrl"].present?
      job_posting.published_at = (Time.zone.at(data["createdAt"] / 1000) rescue Time.zone.now)
      job_posting.company      = data["site_slug"]&.capitalize
      job_posting.location     = data.dig("categories", "location")
      job_posting.tags         = Array(data.dig("categories", "team"))
    when "yc"
      job_posting.title        = data["title"] if data["title"].present?
      job_posting.body         = data["description"] if data["description"].present?
      job_posting.target_url   = data["url"] if data["url"].present?
      job_posting.published_at = Time.zone.now
      job_posting.company      = data["company"]
      job_posting.location     = data["location"]
      job_posting.tags         = Array(data["role_type"])
    when /^email/
      job_posting.title        = data["title"] if data["title"].present?
      job_posting.body         = data["description"] if data["description"].present?
      job_posting.target_url = data["canonical_url"] || data["url"] if (data["canonical_url"] || data["url"]).present?
      job_posting.published_at = (Time.zone.parse(data["email_received_at"]) rescue Time.zone.now)
      job_posting.company      = data["company"]
      job_posting.location     = data["location"]
    when "indeed", "linkedin", "glassdoor", "dice"
      job_posting.title        = data["jobTitle"] || data["title"] if (data["jobTitle"] || data["title"]).present?
      job_posting.company      = data["companyName"] || data["company"]
      job_posting.location     = data["jobGeo"] || data["location"]
      job_posting.target_url   = data["url"] || data["target_url"]
    else
      # Generic Mapper for all other sources (Cord, LinkedIn, Indeed, etc.)
      if (data["title"] || data["job_title"] || data["position"]).present?
        job_posting.title        = (data["title"] || data["job_title"] || data["position"])
      end
      if (data["description"] || data["body"] || data["content"]).present?
        job_posting.body         = (data["description"] || data["body"] || data["content"])
      end
      if (data["url"] || data["link"] || data["target_url"] || data["redirect_url"]).present?
        job_posting.target_url   = (data["url"] || data["link"] || data["target_url"] || data["redirect_url"])
      end
      job_posting.company      = (data["company"] || data["company_name"] || data["employer"])
      job_posting.location     = (data["location"] || data["job_location"] || data["geo"])
    end

    # Preserve intersection data in the JobPosting payload
    job_posting.data = data.merge("found_by_terms" => data["found_by_terms"])

    # ONLY normalize and set body if we actually have one.
    # This prevents overwriting an enriched body with nil during a re-sync.
    new_body = normalize_body(job_posting.body)
    job_posting.body = new_body if new_body.present?
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
end
