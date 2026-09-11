# frozen_string_literal: true

class Resume::SemanticMatchFinder
  def self.call(career_profile, limit: 10)
    return [] if career_profile.embedding.blank?

    # Find nearest neighbors in JobPosting
    JobPosting.where.not(embedding: nil)
              .geo_allowed
              .nearest_neighbors(:embedding, career_profile.embedding, distance: "cosine")
              .limit(limit)
  end
end
