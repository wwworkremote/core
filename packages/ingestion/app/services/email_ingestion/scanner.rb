# frozen_string_literal: true

require "digest"

class EmailIngestion::Scanner
  BASE_DIR = File.expand_path("~/.wwworkremote")
  SOURCES = %w[indeed linkedin adzuna].freeze

  def call
    SOURCES.each do |source|
      source_dir = File.join(BASE_DIR, source)
      next unless Dir.exist?(source_dir)

      Dir.glob(File.join(source_dir, "*.eml")).each do |file_path|
        process_file(file_path, source)
      end
    end
  end

  private

  def process_file(file_path, source)
    checksum = Digest::SHA256.file(file_path).hexdigest

    # Try to claim the file
    record = EmailIngestion::FileClaim.new(file_path, source, checksum).call
    return unless record

    # Enqueue processing
    EmailImportJob.perform_later(record.id)
  end
end
