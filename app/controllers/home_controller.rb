# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @top_matches = Resume::SemanticMatchFinder.call(current_user.career_profile, limit: 6) if current_user.career_profile&.embedding.present?

    @priority_inbox = current_user.user_job_postings.includes(:job_posting).where(priority_flag: true, status: ['none', nil]).limit(6)

    @latest_jobs = JobPosting.recent.limit(6)

    # Efficiently aggregate stats by Origin name
    @source_stats = Origin.joins(sources: :job_postings)
                          .group('origins.name')
                          .count
                          .map { |name, count| { name: name, count: count } }
                          .sort_by { |s| -s[:count] }
                          .first(5)
  end
end
