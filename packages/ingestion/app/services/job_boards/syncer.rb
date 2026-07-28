# frozen_string_literal: true

class JobBoards::Syncer
  def call(limit: 10)
    run_sync(limit)
  rescue ActiveRecord::ConnectionTimeoutError => e
    Rails.logger.error "[Syncer] Database connection pool exhausted: #{e.message}. Halting sync."
    0
  end

  private

  def run_sync(limit)
    pending_docs = fetch_pending_docs(limit)
    processed_count, sources_to_update = process_pending_docs(pending_docs)
    touch_updated_sources(sources_to_update)
    processed_count
  end

  def fetch_pending_docs(limit)
    docs = JobBoards::Document.where(aasm_state: ["pending", nil]).limit(limit)
    Rails.logger.info "[Syncer] Found #{docs.count} pending documents (limited to #{limit})"
    docs
  end

  def process_pending_docs(pending_docs)
    sources_to_update = Set.new
    processed_count = pending_docs.find_each.count { |doc| process_one?(doc, sources_to_update) }
    [processed_count, sources_to_update]
  end

  def process_one?(doc, sources_to_update)
    Rails.logger.info "[Syncer] Processing document #{doc.id} (signature: #{doc.signature[0..8]}...)"
    return false unless sync_document(doc)

    sources_to_update << doc.source_id
    true
  end

  def touch_updated_sources(sources_to_update)
    sources_to_update.each { |source_id| JobBoards::Source.find(source_id).update!(last_ingested_at: Time.current) }
  end

  # Use a transaction and rescue uniqueness errors for high-concurrency safety
  def sync_document(doc)
    build_and_save_posting(doc, JSON.parse(doc.document))
  rescue ActiveRecord::RecordNotUnique
    recover_from_race?(doc)
  rescue StandardError => e
    log_sync_error?(doc, e)
  end

  def log_sync_error?(doc, error)
    Rails.logger.error "[Syncer] Unexpected error syncing document #{doc.id}: #{error.message}"
    false
  end

  # Extreme race condition: another thread created it between find and save.
  def recover_from_race?(doc)
    doc.update!(aasm_state: "processed")
    true
  end

  # Ensure the dashboard Source has a name for telemetry/UI visibility
  def resolve_dashboard_source(source)
    origin = Origin.find_or_create_by!(name: source.name)
    ::Source.find_or_create_by!(signature: "#{source.slug}-default") do |s|
      s.origin = origin
      s.name = source.name # jsonb_accessor will put this in the event field
    end
  end

  def build_and_save_posting(doc, data)
    source = JobBoards::Source.find(doc.source_id)
    job_posting, shielded = find_posting_with_shield(doc)
    return shielded unless shielded.nil?

    prepare_posting(job_posting, data, source)
    save_posting?(job_posting, doc)
  end

  def find_posting_with_shield(doc)
    job_posting = JobPosting.find_or_initialize_by(signature: doc.signature)
    [job_posting, EditShield.call(job_posting, doc)]
  end

  def prepare_posting(job_posting, data, source)
    job_posting.source_id = resolve_dashboard_source(source).id
    AttributeMapper.call(job_posting, data, source.slug)
    CompanyResolver.call(job_posting)
    job_posting.ignore unless JobBoards::QualityFilter.new(job_posting).useful?
  end

  # Capture the result of save in a way that handles race conditions.
  def save_posting?(job_posting, doc)
    return handle_save_failure?(job_posting, doc) unless job_posting.save

    mark_processed(doc)
    enrich_if_needed(job_posting)
    true
  end

  def mark_processed(doc)
    if doc.respond_to?(:processed!)
      doc.processed!
    else
      doc.update!(aasm_state: "processed", updated_at: Time.current)
    end
  end

  # Only categorize if not already enriched/categorized AND not ignored.
  def enrich_if_needed(job_posting)
    return if job_posting.ignored? || job_posting.data["ai_category"].present?

    JobBoards::Categorizer.new(job_posting).call
    JobBoards::Embedder.new(job_posting).call
  end

  # If it failed validation but it was a uniqueness error on signature, we
  # might have lost a race, but the data is there, so mark doc as processed.
  def handle_save_failure?(job_posting, doc)
    return recover_from_race?(doc) if job_posting.errors[:signature].include?("has already been taken")

    log_validation_failure(job_posting, doc)
    false
  end

  def log_validation_failure(job_posting, doc)
    Rails.logger.error "[Syncer] Validation failed for Job signature #{doc.signature}: " \
                       "#{job_posting.errors.full_messages.join(', ')}"
  end
end
