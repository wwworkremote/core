# frozen_string_literal: true

class CompaniesController < ApplicationController
  def index
    @companies = Company.select("companies.*, count(job_postings.id) as job_postings_count")
                        .left_joins(:job_postings)
                        .group("companies.id")
                        .order(job_postings_count: :desc, name: :asc)
                        .page(params[:page]).per(24)
  end

  def show
    @company = Company.includes(:job_postings).find(params.expect(:id))
    load_harness_summary
  end

  private

  # Read-only harness legibility (ADR 010 / TASK-125): how many of this
  # company's applications went through the harness, and each posting's state.
  def load_harness_summary
    tracked = tracked_applications
    @harness_by_posting = tracked.index_by(&:job_posting_id)
    @harness_processed_count = tracked.processed_through_harness.count
    @harness_recorded_sessions = GuidedSession.completed.where(user_job_posting_id: tracked.ids).count
  end

  def tracked_applications
    current_user.user_job_postings.where(job_posting_id: @company.job_postings.map(&:id))
  end
end
