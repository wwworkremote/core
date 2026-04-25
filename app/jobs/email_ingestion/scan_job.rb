# frozen_string_literal: true

module EmailIngestion
  class ScanJob < ApplicationJob
    queue_as :light

    def perform
      EmailIngestion::Scanner.new.call
    end
  end
end
