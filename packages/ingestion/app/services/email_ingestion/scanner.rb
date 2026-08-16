# frozen_string_literal: true

require "digest"

class EmailIngestion::Scanner
  BASE_DIR = File.expand_path("~/.wwworkremote")
  SOURCES = %w[indeed linkedin adzuna].freeze

  def call(source: nil)
    (source ? [source] : SOURCES).each { |src| scan_source(src) }
  end

  private

  def scan_source(source)
    source_dir = File.join(BASE_DIR, source)
    return unless Dir.exist?(source_dir)

    Dir.glob(File.join(source_dir, "*.eml")).each { |file_path| process_file(file_path, source) }
  end

  def process_file(file_path, source)
    checksum = Digest::SHA256.file(file_path).hexdigest

    # Try to claim the file
    record = EmailIngestion::FileClaim.new(file_path, source, checksum).call
    return unless record

    # Enqueue processing
    EmailImportJob.perform_later(record.id)
  end
end
