# frozen_string_literal: true

require "rails_helper"

RSpec.describe "External Ingestion Integrity" do
  let(:providers) { %w[indeed linkedin adzuna glassdoor dice remotive wwr arbeitnow] }

  describe "Golden Cassette Audit" do
    it "verifies existence of golden cassettes for all providers" do
      providers.each do |provider|
        cassette_path = Rails.root.join("spec/cassettes/#{provider}_fetch.yml")
        # We allow fallback names or combined ones if they exist
        expect(File.exist?(cassette_path)).to be(true), "Missing Golden Cassette for #{provider} at #{cassette_path}"
      end
    end
  end

  describe "Extractor Contract Audit" do
    it "verifies that CanonicalJobExtractor has field selectors configured for each provider" do
      providers.each do |provider|
        expect(JobFetchers::CanonicalJobExtractor::Selectors::FIELD_SELECTORS).to have_key(provider),
                                                                                   "CanonicalJobExtractor is missing selectors for #{provider}"
      end
    end
  end
end
