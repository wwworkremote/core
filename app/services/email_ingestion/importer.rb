# frozen_string_literal: true

require 'digest'
require 'fileutils'

module EmailIngestion
  class Importer
    def initialize(record = nil)
      @record = record
      @source_provider = record&.source
      @file_path = record&.file_path
    end

    def call(source: nil, force: false)
      if @record
        process_record
      else
        # When called without a record, perform a scan for the given source
        rake = Rake::Application.new
        Rake.application = rake
        Rake::Task.define_task(:environment)
        load Rails.root.join('lib/tasks/eml.rake')
        rake['eml:scan_source'].invoke(source)

      end
    end

    private

    def process_record
      @record.update!(status: 'processing')

      begin
        # 1. Parse Email
        parsed_email = EmailIngestion::MessageParser.new(@file_path).call
        @record.update!(message_id: parsed_email[:message_id])

        # 2. Extract Links
        job_links = EmailIngestion::LinkExtractor.new(parsed_email, @source_provider).call

        if job_links.empty?
          @record.update!(status: 'processed', processed_at: Time.current)
          EmailIngestion::FileLifecycle.new(@file_path, @source_provider).processed
          return
        end

        # 3. Resolve & Fetch each job link
        processed_jobs_count = 0
        job_links.each do |job_link|
          process_job_link(job_link, parsed_email)
          processed_jobs_count += 1
        end

        # 4. Sync Job Postings (from Documents created in process_job_link)
        JobBoards::Syncer.new.call

        @record.update!(status: 'processed', processed_at: Time.current)
        EmailIngestion::FileLifecycle.new(@file_path, @source_provider).processed
      rescue StandardError => e
        @record.update!(status: 'error', error_message: e.message)
        EmailIngestion::FileLifecycle.new(@file_path, @source_provider).error
        Rails.logger.error "[EmailIngestion::Importer] Error for record #{@record.id}: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end

    def process_job_link(job_link, parsed_email)
      # a. Resolve Canonical URL
      canonical_url = EmailIngestion::CanonicalUrlResolver.new(job_link).call

      # b. Idempotency Check for this specific job link in this email
      signature = Digest::SHA256.hexdigest("#{@record.message_id}-#{canonical_url}")
      return if JobBoards::Document.exists?(signature: signature)

      # c. Fetch content
      fetch_result = JobFetchers::PageFetch.new(canonical_url).call
      return unless fetch_result

      # d. Extract metadata
      job_data = JobFetchers::CanonicalJobExtractor.new(fetch_result[:content], fetch_result[:final_url], @source_provider).call

      # e. Create JobBoards::Document
      source_slug = 'email_ingestion'
      source = JobBoards::Source.find_or_create_by!(slug: source_slug) do |s|
        s.name = 'Email Ingestion'
      end
      query = JobBoards::Query.find_or_create_by!(source_id: source.id)

      # Enrich job_data with email provenance
      enriched_data = job_data.merge(
        source_provider: @source_provider,
        email_message_id: @record.message_id,
        email_file_path: @file_path,
        email_received_at: parsed_email[:date],
        discovered_url: job_link,
        canonical_url: canonical_url,
        final_fetch_url: fetch_result[:final_url],
        fetch_mode: fetch_result[:fetch_mode]
      )

      doc = JobBoards::Document.find_or_initialize_by(signature: signature)
      return unless doc.new_record?
      doc.source_id = source.id
      doc.job_boards_query_id = query.id
      doc.document = enriched_data.to_json
      return if doc.save
      Rails.logger.error "[EmailIngestion::Importer] Failed to save document #{signature}: #{doc.errors.full_messages.join(', ')}"
    end
  end
end
