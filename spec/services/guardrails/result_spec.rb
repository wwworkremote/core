# frozen_string_literal: true

require "rails_helper"

RSpec.describe Guardrails::Result do
  let(:result) { described_class.new(allowed: true, risk_level: "low", findings: [], disposition: "allow") }

  describe "#allowed?" do
    it "returns true if allowed" do
      expect(result.allowed?).to be true
    end
  end

  describe "#high_risk?" do
    it "returns true if risk level is high" do
      high_risk_result = described_class.new(allowed: false, risk_level: "high")
      expect(high_risk_result.high_risk?).to be true
    end
  end

  describe "#blocked?" do
    it "returns true if disposition is block" do
      blocked_result = described_class.new(allowed: false, disposition: "block")
      expect(blocked_result.blocked?).to be true
    end
  end
end
