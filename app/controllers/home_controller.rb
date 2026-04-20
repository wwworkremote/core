# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    if current_user.career_profile&.embedding.present?
      @top_matches = Resume::SemanticMatchFinder.call(current_user.career_profile, limit: 6)
    end
    
    @priority_inbox = current_user.user_job_postings.includes(:job_posting).where(priority_flag: true, status: ['none', nil]).limit(6)
    
    @latest_jobs = JobPosting.recent.limit(6)
    @source_stats = JobBoards::Source.all.map { |s| { name: s.name, count: s.job_postings.count } }.sort_by { |s| -s[:count] }.first(5)
  end
end
