# frozen_string_literal: true

class EmailScanJob < ApplicationJob
  queue_as :light

  def perform
    EmailScanner.new.call
  end
end
