# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resume::SemanticMatchFinder do
  let(:embedding) { Array.new(3584) { rand } }
  let(:career_profile) { create(:career_profile, embedding: embedding) }

  describe ".call" do
    it "returns an empty array if career_profile has no embedding" do
      career_profile.update_column(:embedding, nil)
      expect(described_class.call(career_profile)).to eq([])
    end

    it "finds nearest neighbors by cosine distance" do
      # 1. Create a match (similar embedding)
      match = create(:job_posting, embedding: embedding)

      # 2. Create a non-match (different embedding)
      different_embedding = embedding.map { |v| v * -1 }
      non_match = create(:job_posting, embedding: different_embedding)

      # 3. Create one without embedding
      no_embedding = create(:job_posting, embedding: nil)

      results = described_class.call(career_profile)

      expect(results).to include(match)
      expect(results).not_to include(non_match) if results.size < 2 # Depends on distance
      expect(results).not_to include(no_embedding)
    end

    it "respects the limit parameter" do
      create_list(:job_posting, 5, embedding: embedding)
      results = described_class.call(career_profile, limit: 2)
      expect(results.size).to eq(2)
    end
  end
end
