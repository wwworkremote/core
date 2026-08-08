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

  private

  def assign_filter_params
    @query = params[:q]
    @company = params[:company]
    @source_id = params[:source_id]
    @role_family = valid_role_family_param
  end

  def valid_role_family_param
    return nil unless ROLE_FAMILY_LABELS.key?(params[:role_family]&.to_sym)

    params[:role_family]
  end

  def filtered_job_postings
    scope = base_job_postings
    scope = scope.where(company_name: @company) if @company.present?
    scope = scope.where(source_id: @source_id) if @source_id.present?
    apply_query_and_role_family(scope)
  end

  def apply_query_and_role_family(scope)
    scope = scope.search(@query) if @query.present?
    scope = scope.by_role_family(@role_family.to_sym) if @role_family.present?
    scope
  end

  def base_job_postings
    scope = JobPosting.recent.includes(source: :origin)
    scope = scope.where.not(status: %w[ignored purged expired]) if params[:status].blank?
    scope
  end
end
