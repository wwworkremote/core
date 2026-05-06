# frozen_string_literal: true

module JobSearchManager
  # Orchestrates job search campaigns and provides high-leverage matching.

  class MatcherService
    def initialize(job_search)
      @job_search = job_search
      @resume = job_search.resume
    end

    def call(limit: 10)
      return JobPosting.none unless @resume&.embedding

      # Leverage VectorIntelligence for the core ranking operation.
      # This keeps the strategy centralized while providing campaign-specific context.
      VectorIntelligence.rank(
        source: @resume,
        target_class: JobPosting,
        limit: limit
      )
    end

    def skills_analysis(limit: 10)
      return Skill.none unless @resume&.embedding

      VectorIntelligence.rank(
        source: @resume,
        target_class: Skill,
        limit: limit
      )
    end
  end
end
