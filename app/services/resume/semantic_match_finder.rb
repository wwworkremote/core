# frozen_string_literal: true

module Resume
  class SemanticMatchFinder
    def self.call(career_profile, limit: 10)
      return [] unless career_profile.embedding.present?

      # Find nearest neighbors in JobPosting
      JobPosting.where.not(embedding: nil)
                .nearest_neighbors(:embedding, career_profile.embedding, distance: 'cosine')
                .limit(limit)
    end
  end
end
