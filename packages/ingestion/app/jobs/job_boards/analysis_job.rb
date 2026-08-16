# frozen_string_literal: true

class JobBoards::AnalysisJob < ApplicationJob
  queue_as :heavy
  heavyweight!
  idempotent! ->(job_posting_id) { "analysis/#{job_posting_id}" }

  def perform(job_posting_id)
    job_posting = JobPosting.find_by(id: job_posting_id)
    return unless job_posting
    # Re-check at execution time, not just enqueue time -- GeocodingJob
    # (:light queue) runs a fast HTTP call and can complete + auto-ignore
    # via enforce_commute_zone before this job (:heavy queue) actually
    # executes, even though both get enqueued around the same moment
    # (TASK-54). Not a full fix for the race -- just avoids paying the LLM
    # cost in the common case where the faster queue wins.
    return if job_posting.ignored?

    JobBoards::Categorizer.new(job_posting).call
    JobBoards::Embedder.new(job_posting).call
  end
end
