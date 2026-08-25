# frozen_string_literal: true

# Orchestrates job search campaigns and provides high-leverage matching.
class JobSearchManager::MatcherService
  def initialize(job_search)
    @job_search = job_search
    @resume = job_search.resume
  end

  # Leverage VectorIntelligence for the core ranking operation. This keeps
  # the strategy centralized while providing campaign-specific context.
  def call(limit: 10)
    return JobPosting.none unless @resume&.embedding

    rank(JobPosting.geo_allowed, limit)
  end

  def skills_analysis(limit: 10)
    return Skill.none unless @resume&.embedding

    rank(Skill, limit)
  end

  private

  def rank(target_class, limit)
    VectorIntelligence.rank(source: @resume, target_class: target_class, limit: limit)
  end
end
