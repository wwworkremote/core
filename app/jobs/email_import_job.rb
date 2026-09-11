# frozen_string_literal: true

class EmailImportJob < ApplicationJob
  # Launches a real Playwright headless browser as a fallback fetch -- genuinely
  # memory/CPU heavy, unlike most :light jobs. Moved off :light (5 threads in
  # dev) onto :heavy (1-2 threads) plus its own concurrency ceiling so it can't
  # spawn several browsers at once on a memory-constrained box.
  queue_as :heavy
  heavyweight!
  idempotent!

  def perform(record_id)
    record = EmailImportRecord.find(record_id)
    EmailIngestion::Importer.new(record).call
  end
end
