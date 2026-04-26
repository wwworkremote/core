# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quality::ContextBuilder do
  describe ".architectural_constraints_for" do
    let(:file_path) { "app/models/user.rb" }
    let!(:insight) do
      create(:system_insight, 
        tool: :rubocop, 
        severity: :warning, 
        file_path: file_path, 
        message: "Prefer double quotes", 
        line_number: 10
      )
    end

    it "formats active insights into a prompt section" do
      result = described_class.architectural_constraints_for(file_path)
      expect(result).to include("SYSTEM_QUALITY_CONSTRAINTS")
      expect(result).to include("[RUBOCOP] Architectural Constraints")
      expect(result).to include("[WARNING] L10: Prefer double quotes")
    end

    it "returns empty string if no insights found" do
      expect(described_class.architectural_constraints_for("other.rb")).to eq("")
    end

    it "excludes inactive insights" do
      insight.update!(active: false)
      expect(described_class.architectural_constraints_for(file_path)).to eq("")
    end
  end
end
