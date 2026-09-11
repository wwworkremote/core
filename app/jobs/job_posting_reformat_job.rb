# frozen_string_literal: true

class JobPostingReformatJob < ApplicationJob
  queue_as :heavy
  heavyweight!
  idempotent! ->(job_posting_id) { "job_posting_reformat/#{job_posting_id}" }

  def perform(job_posting_id)
    job_posting = JobPosting.find(job_posting_id)
    JobBoards::Reformatter.new(job_posting).call
    broadcast_description(job_posting)
  end

  private

  def broadcast_description(job_posting)
    target = ActionView::RecordIdentifier.dom_id(job_posting, :description)
    job_posting.broadcast_replace_to(job_posting, target: target, partial: "job_postings/description",
                                                  locals: { job_posting: job_posting })
  end
end
