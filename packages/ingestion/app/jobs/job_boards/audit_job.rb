# frozen_string_literal: true

class JobBoards::AuditJob < ApplicationJob
  queue_as :light
  mediumweight!

  def perform(limit: 100)
    stats = JobBoards::Auditor.new(fix: true, limit: limit).call
    Rails.logger.info "[AuditJob] Completed: #{stats.inspect}"
  end
end
