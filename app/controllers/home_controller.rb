# frozen_string_literal: true

class HomeController < ApplicationController
  PRIORITY_INBOX_STATUSES = ["none", nil].freeze

  def index
    assign_top_matches
    assign_priority_inbox
    @latest_jobs = JobPosting.recent.limit(6)
    @source_stats = top_source_stats
  end

  private

  def assign_top_matches
    return if current_user.career_profile&.embedding.blank?

    @top_matches = Resume::SemanticMatchFinder.call(current_user.career_profile, limit: 6)
  end

  def assign_priority_inbox
    @priority_inbox = current_user.user_job_postings
                                  .includes(:job_posting)
                                  .where(priority_flag: true, status: PRIORITY_INBOX_STATUSES)
                                  .limit(6)
  end

  # Efficiently aggregate stats by Origin name -- one cohesive query
  # chain, splitting it further would obscure it, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def top_source_stats
    Origin.joins(sources: :job_postings)
          .group("origins.name")
          .count
          .map { |name, count| { name: name, count: count } }
          .sort_by { |s| -s[:count] }
          .first(5)
  end
  # rubocop:enable Metrics/MethodLength
end
