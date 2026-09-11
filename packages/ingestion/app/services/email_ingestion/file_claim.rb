# frozen_string_literal: true

class EmailIngestion::FileClaim
  def initialize(file_path, source, checksum)
    @file_path = file_path
    @source = source
    @checksum = checksum
  end

  # rubocop:disable-next Metrics/MethodLength
  def call
    EmailImportRecord.transaction do
      existing = EmailImportRecord.find_by(file_checksum: @checksum)
      existing ? retry_if_errored(existing) : create_record
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end

  private

  # Only retry on error -- if it was an error, we can try again
  def retry_if_errored(record)
    return nil if record.status != "error"

    record.update!(status: "pending", error_message: nil)
    record
  end

  # rubocop:disable-next Metrics/MethodLength
  def create_record
    EmailImportRecord.create!(
      file_path: @file_path,
      source: @source,
      file_checksum: @checksum,
      status: "pending"
    )
  end
end
