# frozen_string_literal: true

require "fileutils"

class EmailIngestion::Importer
  def initialize(record = nil)
    @record = record
    @source_provider = record&.source
    @file_path = record&.file_path
  end

  def call(source: nil)
    return process_record if @record

    # When called without a record, perform a scan for the given source
    scan_source(source)
  end

  private

  def scan_source(source)
    rake = Rake::Application.new
    Rake.application = rake
    Rake::Task.define_task(:environment)
    load Rails.root.join("lib/tasks/eml.rake")
    rake["eml:scan_source"].invoke(source)
  end

  def process_record
    @record.update!(status: "processing")
    import_from_email
  rescue StandardError => e
    handle_import_error(e)
  end

  def import_from_email
    parsed_email = parse_email
    job_links = EmailIngestion::LinkExtractor.new(parsed_email, @source_provider).call
    return mark_processed if job_links.empty?

    process_job_links(job_links, parsed_email)
  end

  def process_job_links(job_links, parsed_email)
    job_links.each { |job_link| EmailIngestion::JobLinkProcessor.new(job_link, parsed_email, @record).call }
    JobBoards::Syncer.new.call
    mark_processed
  end

  def parse_email
    parsed_email = EmailIngestion::MessageParser.new(@file_path).call
    @record.update!(message_id: parsed_email[:message_id])
    parsed_email
  end

  def mark_processed
    moved_to = EmailIngestion::FileLifecycle.new(@file_path, @source_provider).processed
    @record.update!(status: "processed", processed_at: Time.current, file_path: moved_to || @file_path)
  end

  # Persist the file's new location even on failure -- otherwise a retry looks for the file at
  # the pre-move path, gets Errno::ENOENT, and permanently masks the real error above.
  def handle_import_error(error)
    moved_to = EmailIngestion::FileLifecycle.new(@file_path, @source_provider).error
    @record.update!(status: "error", error_message: error.message, file_path: moved_to || @file_path)
    log_import_error(error)
  end

  def log_import_error(error)
    Rails.logger.error "[EmailImporter] Error for record #{@record.id}: #{error.message}\n#{error.backtrace.join("\n")}"
  end
end
