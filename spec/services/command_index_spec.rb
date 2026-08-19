# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommandIndex do
  before { Rails.cache.clear }

  describe ".entries" do
    it "includes real named pages with human-readable labels" do
      entries = described_class.entries

      expect(entries).to include(a_hash_including(label: "Job Postings", path: "/job_postings"))
      expect(entries).to include(a_hash_including(label: "Companies", path: "/companies"))
      expect(entries).to include(a_hash_including(label: "Dashboard", path: "/"))
      expect(entries).to include(a_hash_including(label: "Admin Dashboard", path: "/admin"))
    end

    it "excludes routes with required dynamic segments -- not directly navigable" do
      entries = described_class.entries

      expect(entries.pluck(:path)).not_to include(a_string_matching(/:id|:slug/))
    end

    it "excludes internal/infrastructure routes (Rails engines, API, Turbo)" do
      entries = described_class.entries
      paths = entries.pluck(:path)

      expect(paths.grep(%r{\A/rails/})).to be_empty
      expect(paths.grep(%r{\A/api/})).to be_empty
      expect(paths.grep(%r{\A/charts/})).to be_empty
    end

    it "excludes non-GET routes" do
      entries = described_class.entries

      expect(entries.pluck(:path)).not_to include("/data_fetchers/run")
    end

    it "is cached" do
      described_class.entries
      expect(Rails.cache).to exist("command_index/entries")
    end
  end
end
