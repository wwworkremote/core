# frozen_string_literal: true

class JobBoards::AnalysisJob < ApplicationJob
  queue_as :heavy
  heavyweight!
  idempotent! ->(job_posting_id) { "analysis/#{job_posting_id}" }

  def perform(job_posting_id)
    job_posting = JobPosting.find_by(id: job_posting_id)
    return unless job_posting

    JobBoards::Categorizer.new(job_posting).call
    JobBoards::Embedder.new(job_posting).call
  end
end
