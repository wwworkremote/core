# frozen_string_literal: true

class JobPostingsController < ApplicationController
  ROLE_FAMILY_LABELS = {
    staff_plus_ic: "Staff+ IC",
    engineering_management: "Engineering Mgmt",
    product_leadership: "Product Leadership",
    design_leadership: "Design Leadership",
    data_leadership: "Data Leadership"
  }.freeze
  helper_method :role_family_labels

  def index
    assign_filter_params
    @job_postings = filtered_job_postings.page(params[:page]).per(20)
  end

  def show
    @job_posting = JobPosting.includes(:contacts).find(params.expect(:id))
    ahoy.track "Viewed Job Posting", job_posting_id: @job_posting.id, title: @job_posting.title
  end

  def role_family_labels
    ROLE_FAMILY_LABELS
  end

  # Single source of truth for "every active filter, as URL params" -- the
  # view builds every filter-badge/remove link off this hash (via #except /
  # #merge) instead of hand-threading each param through every link_to, which
  # silently drops filters whenever a new one is added and someone forgets a
  # spot.
  def active_filter_params
    {
      q: @query, company: @company, source_id: @source_id, role_family: @role_family,
      location: @location, remote: (@remote ? "1" : nil), contract: (@contract ? "1" : nil)
    }
  end
  helper_method :active_filter_params

  private

  def assign_filter_params
    @query = params[:q]
    @company = params[:company]
    @source_id = params[:source_id]
    @role_family = valid_role_family_param
    assign_location_params
  end

  def assign_location_params
    @location = params[:location]
    @remote = params[:remote] == "1"
    @contract = params[:contract] == "1"
  end

  def valid_role_family_param
    return nil unless ROLE_FAMILY_LABELS.key?(params[:role_family]&.to_sym)

    params[:role_family]
  end

  def filtered_job_postings
    scope = base_job_postings
    scope = scope.where(company_name: @company) if @company.present?
    scope = scope.where(source_id: @source_id) if @source_id.present?
    scope = apply_location_filter(scope)
    apply_query_and_role_family(scope)
  end

  # Location text and "Remote" combine as OR, not AND -- "Chicago" + Remote
  # checked means jobs near Chicago OR remote (either is accessible), the
  # standard job-board convention, not jobs that are somehow both at once.
  def apply_location_filter(scope)
    filter = location_filter_scope
    filter ? scope.merge(filter) : scope
  end

  def location_filter_scope
    return nil if @location.blank? && !@remote
    return JobPosting.remote_only if @location.blank?
    return JobPosting.location_matches(@location) unless @remote

    JobPosting.location_matches(@location).or(JobPosting.remote_only)
  end

  def apply_query_and_role_family(scope)
    scope = scope.search(@query) if @query.present?
    scope = scope.by_role_family(@role_family.to_sym) if @role_family.present?
    scope = scope.contract_only if @contract
    scope
  end

  def base_job_postings
    scope = JobPosting.recent.includes(:company, source: :origin)
    scope = scope.where.not(status: %w[ignored purged expired]) if params[:status].blank?
    scope
  end
end
