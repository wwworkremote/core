# frozen_string_literal: true

require "digest"

# Resolves, fetches, and persists one discovered job link from an email as a
# JobBoards::Document -- split out of EmailIngestion::Importer to keep that
# class under Metrics/ClassLength.
class EmailIngestion::JobLinkProcessor
  Context = Struct.new(:job_link, :canonical_url, :fetch_result, :parsed_email, keyword_init: true)

  def self.call(...)
    new(...).call
  end

  def initialize(job_link, parsed_email, record)
    @job_link = job_link
    @parsed_email = parsed_email
    @record = record
    @source_provider = record.source
    @file_path = record.file_path
  end

  def call
    resolved = resolve
    return unless resolved

    save_document(*resolved)
  end

  private

  def resolve
    canonical_url = EmailIngestion::CanonicalUrlResolver.new(@job_link).call
    signature = link_signature(canonical_url)
    return nil if JobBoards::Document.exists?(signature: signature)

    fetch_and_extract(signature, canonical_url)
  end

  def link_signature(canonical_url)
    Digest::SHA256.hexdigest("#{@record.message_id}-#{canonical_url}")
  end

  def fetch_and_extract(signature, canonical_url)
    fetch_result = JobFetchers::PageFetch.new(canonical_url).call
    return nil unless fetch_result

    job_data = extract_job_data(fetch_result)
    return nil unless job_data

    [signature, job_data, build_context(canonical_url, fetch_result)]
  end

  def build_context(canonical_url, fetch_result)
    Context.new(job_link: @job_link, canonical_url: canonical_url, fetch_result: fetch_result,
                parsed_email: @parsed_email)
  end

  def extract_job_data(fetch_result)
    JobFetchers::CanonicalJobExtractor.new(fetch_result[:content], fetch_result[:final_url], @source_provider).call
  end

  def save_document(signature, job_data, context)
    doc = JobBoards::Document.find_or_initialize_by(signature: signature)
    return unless doc.new_record?

    assign_document_attrs(doc, job_data, context)
    log_save_failure(signature, doc) unless doc.save
  end

  def assign_document_attrs(doc, job_data, context)
    doc.source_id = email_ingestion_source.id
    doc.job_boards_query_id = email_ingestion_query.id
    doc.document = enriched_data(job_data, context).to_json
  end

  def email_ingestion_source
    @email_ingestion_source ||=
      JobBoards::Source.find_or_create_by!(slug: "email_ingestion") { |s| s.name = "Email Ingestion" }
  end

  def email_ingestion_query
    @email_ingestion_query ||= JobBoards::Query.find_or_create_by!(source_id: email_ingestion_source.id)
  end

  # Enrich job_data with email provenance
  def enriched_data(job_data, context)
    job_data.merge(base_provenance.merge(link_provenance(context)))
  end

  def base_provenance
    { source_provider: @source_provider, email_message_id: @record.message_id, email_file_path: @file_path }
  end

  def link_provenance(context)
    { email_received_at: context.parsed_email[:date], discovered_url: context.job_link,
      canonical_url: context.canonical_url, final_fetch_url: context.fetch_result[:final_url],
      fetch_mode: context.fetch_result[:fetch_mode] }
  end

  def log_save_failure(signature, doc)
    Rails.logger.error "[EmailImporter] Failed to save document #{signature}: #{doc.errors.full_messages.join(', ')}"
  end
end
