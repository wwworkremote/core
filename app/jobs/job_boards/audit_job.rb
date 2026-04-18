# frozen_string_literal: true

module JobBoards
  class AuditJob < ApplicationJob
    queue_as :default

    def perform(limit: 100)
      stats = Auditor.new(fix: true, limit: limit).call
      Rails.logger.info "[AuditJob] Completed: #{stats.inspect}"
    end
  end
end
