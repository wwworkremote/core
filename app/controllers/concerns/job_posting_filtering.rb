# frozen_string_literal: true

# Everything JobPostingsController#index needs to turn query params into a
# scoped JobPosting relation. Pulled out of the controller on its own --
# show/update/reformat share nothing with this beyond the class -- so the
# controller can grow member actions without tripping ClassLength on an
# unrelated concern.
module JobPostingFiltering
  extend ActiveSupport::Concern

  ROLE_FAMILY_LABELS = {
    staff_plus_ic: "Staff+ IC",
    engineering_management: "Engineering Mgmt",
    product_leadership: "Product Leadership",
    design_leadership: "Design Leadership",
    data_leadership: "Data Leadership"
  }.freeze

  included do
    helper_method :role_family_labels, :active_filter_params
  end

  def role_family_labels
    ROLE_FAMILY_LABELS
  end

  # Single source of truth for "every active filter, as URL params" -- every
  # filter-badge/remove link builds off this hash instead of hand-threading
  # each param through every link_to, which silently drops filters whenever
  # a new one is added and someone forgets a spot.
  def active_filter_params
    {
      q: @query, company: @company, source_id: @source_id, role_family: @role_family,
      location: @location, remote: (@remote ? "1" : nil), contract: (@contract ? "1" : nil), sort: @sort
    }
  end

  private

  def assign_filter_params
    @query = params[:q]
    @company = params[:company]
    @source_id = params[:source_id]
    @role_family = valid_role_family_param
    assign_location_params
  end

  def valid_sort_param
    params[:sort] if %w[match_score company].include?(params[:sort])
  end

  def assign_location_params
    @location = params[:location]
    @remote = params[:remote] == "1"
    @contract = params[:contract] == "1"
    @sort = valid_sort_param
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
    scope = apply_search(scope) if @query.present?
    scope = scope.by_role_family(@role_family.to_sym) if @role_family.present?
    scope = scope.contract_only if @contract
    scope
  end

  # hybrid_search fuses keyword (pg_search) and vector (pgvector) results via
  # RRF, but runs unscoped -- reorder(nil) drops the .recent order so match
  # relevance wins over recency once a query is present.
  def apply_search(scope)
    ranked_ids = JobPosting.hybrid_search(@query, limit: 200).pluck(:id)
    scope.where(id: ranked_ids).reorder(nil).in_order_of(:id, ranked_ids)
  end

  def base_job_postings
    scope = base_sort_scope.includes(:company, source: :origin)
    scope = scope.where.not(status: %w[ignored purged expired]) if params[:status].blank?
    scope
  end

  def base_sort_scope
    return JobPosting.by_match_score(current_user) if @sort == "match_score"

    @sort == "company" ? JobPosting.by_company : JobPosting.recent
  end
end
