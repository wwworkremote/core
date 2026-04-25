# frozen_string_literal: true

class EmailIngestion::FileClaim
  def initialize(file_path, source, checksum)
    @file_path = file_path
    @source = source
    @checksum = checksum
  end

  def call
    EmailImportRecord.transaction do
      record = EmailImportRecord.find_by(file_checksum: @checksum)

      if record
        return nil if record.status != 'error' # Only retry on error
        # If it was an error, we can try again
        record.update!(status: 'pending', error_message: nil)
        return record
      end

      EmailImportRecord.create!(
        file_path: @file_path,
        source: @source,
        file_checksum: @checksum,
        status: 'pending'
      )
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end
end
