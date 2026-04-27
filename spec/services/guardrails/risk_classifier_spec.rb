# frozen_string_literal: true

require "rails_helper"

RSpec.describe Guardrails::RiskClassifier do
  describe "#call" do
    it "classifies score >= 100 as high risk / block" do
      result = described_class.new(100, ["Prompt injection"]).call
      expect(result[:risk_level]).to eq("high")
      expect(result[:disposition]).to eq("block")
    end

    it "classifies score >= 50 as high risk / quarantine" do
      result = described_class.new(50, ["Suspicious pattern"]).call
      expect(result[:risk_level]).to eq("high")
      expect(result[:disposition]).to eq("quarantine")
    end

    it "classifies score >= 20 as medium risk / allow" do
      result = described_class.new(20, ["Weak match"]).call
      expect(result[:risk_level]).to eq("medium")
      expect(result[:disposition]).to eq("allow")
    end

    it "classifies score < 20 as low risk / allow" do
      result = described_class.new(0, []).call
      expect(result[:risk_level]).to eq("low")
      expect(result[:disposition]).to eq("allow")
    end
  end
end
