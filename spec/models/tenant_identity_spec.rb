# frozen_string_literal: true

require "rails_helper"

RSpec.describe TenantIdentity do
  describe ".for" do
    it "creates one row per (provider, identifier) and returns the same row on repeat" do
      first = described_class.for(provider: "greenhouse", identifier: "acme")
      second = described_class.for(provider: "greenhouse", identifier: "acme")

      expect(first).to eq(second)
      expect(described_class.where(provider: "greenhouse", identifier: "acme").count).to eq(1)
    end

    it "keeps the same identifier distinct across providers" do
      gh = described_class.for(provider: "greenhouse", identifier: "acme")
      lever = described_class.for(provider: "lever", identifier: "acme")

      expect(gh).not_to eq(lever)
    end

    it "returns nil when the employer cannot be attributed" do
      expect(described_class.for(provider: "greenhouse", identifier: nil)).to be_nil
      expect(described_class.for(provider: nil, identifier: "acme")).to be_nil
    end
  end
end
