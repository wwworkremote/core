# frozen_string_literal: true

class JobBoards::StrategyJob < ApplicationJob
  queue_as :heavy
  heavyweight!
  idempotent! ->(job_posting_id, user_id) { "strategy/#{job_posting_id}-#{user_id}" }

  def perform(job_posting_id, user_id)
    job_posting = JobPosting.find_by(id: job_posting_id)
    return unless job_posting

    user_job_posting = UserJobPosting.find_or_create_by!(job_posting_id: job_posting_id, user_id: user_id)
    JobBoards::StrategyAgent.new.call(job_posting, user_job_posting)
  end
end
