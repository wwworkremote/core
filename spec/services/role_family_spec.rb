# frozen_string_literal: true

require "rails_helper"

RSpec.describe RoleFamily do
  describe ".for" do
    it "matches a real staff-plus IC title" do
      expect(described_class.for("Senior Staff Software Engineer, Developer Infrastructure")).to eq(:staff_plus_ic)
    end

    it "matches a real engineering management title" do
      expect(described_class.for("Engineering Manager, Contracting Platform")).to eq(:engineering_management)
    end

    it "is case-insensitive" do
      expect(described_class.for("staff engineer")).to eq(:staff_plus_ic)
    end

    it "returns nil for a title matching no family" do
      expect(described_class.for("Senior Software Engineer")).to be_nil
    end

    it "returns nil for a blank title" do
      expect(described_class.for("")).to be_nil
      expect(described_class.for(nil)).to be_nil
    end
  end

  describe ".aliases_for" do
    it "returns the alias list for a known family" do
      expect(described_class.aliases_for(:staff_plus_ic)).to include("Staff Engineer", "Principal Engineer")
    end

    it "returns an empty array for an unknown family" do
      expect(described_class.aliases_for(:not_a_family)).to eq([])
    end
  end
end
