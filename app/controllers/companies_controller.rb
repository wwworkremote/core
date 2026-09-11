# frozen_string_literal: true

class CompaniesController < ApplicationController
  # The index composes the query from independent URL filters.
  # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
  def index
    scope = Company.select("companies.*, count(job_postings.id) as job_postings_count")
                   .left_joins(:job_postings)
                   .group("companies.id")
    @query = params[:q].to_s.strip
    scope = scope.where("companies.name ILIKE ?", "%#{Company.sanitize_sql_like(@query)}%") if @query.present?
    scope = scope.where(ingestion_enabled: true) if params[:active] == "1"
    scope = scope.where(toxic_culture_flag: true) if params[:flagged] == "1"
    scope = scope.where("last_declined_at > ?", Company::COOLDOWN.ago) if params[:cooldown] == "1"
    @companies = scope.order(job_postings_count: :desc, name: :asc)
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
