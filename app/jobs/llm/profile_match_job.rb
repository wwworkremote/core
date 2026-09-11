# frozen_string_literal: true

class LLM::ProfileMatchJob < ApplicationJob
  queue_as :heavy
  heavyweight!
  idempotent! ->(user_id, job_posting_id) { "profile_match/#{user_id}-#{job_posting_id}" }

  def perform(user_id, job_posting_id)
    user = User.find_by(id: user_id)
    job_posting = JobPosting.find_by(id: job_posting_id)
    return unless user && job_posting

    LLM::ProfileMatcher.call(user, job_posting)
  end
end
