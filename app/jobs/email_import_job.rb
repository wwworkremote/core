# frozen_string_literal: true

class EmailImportJob < ApplicationJob
  queue_as :default

  def perform(record_id)
    record = EmailImportRecord.find(record_id)
    EmailIngestion::Importer.new(record).call
  end
end
