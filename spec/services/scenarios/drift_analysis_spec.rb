# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::DriftAnalysis do
  def analyse(candidate, reference, purpose)
    described_class.call(candidate, reference: reference, purpose: purpose)
  end

  it "stamps the comparison rules version" do
    reference = scenario_with([["step:intake.1", "x"]])
    candidate = scenario_with([["step:intake.1", "x"]])

    expect(analyse(candidate, reference, "application_execution")[:rules_version])
      .to eq(Scenarios::ComparisonRules::VERSION)
  end

  it "produces zero drift when a research session stops at the commitment boundary" do
    reference = scenario_with([
                                ["step:intake.1", "x"], ["step:resolution.1", "x"],
                                ["commitment_boundary:submit", "pending"], ["step:reorientation.1", "x"],
                                ["field:signature", "text|identity|required"]
                              ])
    candidate = scenario_with([["step:intake.1", "x"], ["step:resolution.1", "x"]])

    result = analyse(candidate, reference, "application_research")

    expect(result[:drift]).to eq(gained: [], lost: [], changed: [])
    expect(result[:coverage][:ratio]).to eq(1.0)
  end

  it "treats a reference marker missing within Reached Scope as drift" do
    reference = scenario_with([
                                ["step:intake.1", "x"], ["field:email", "email|identity|required"],
                                ["step:resolution.1", "x"], ["step:reorientation.1", "x"]
                              ])
    candidate = scenario_with([["step:intake.1", "x"], ["step:resolution.1", "x"], ["step:reorientation.1", "x"]])

    expect(analyse(candidate, reference, "application_execution")[:drift][:lost]).to eq(["field:email"])
  end

  it "treats a candidate-only marker as drift regardless of scope" do
    reference = scenario_with([["step:intake.1", "x"]])
    candidate = scenario_with([["step:intake.1", "x"], ["field:referral_source", "text|identity|optional"]])

    expect(analyse(candidate, reference, "application_execution")[:drift][:gained]).to eq(["field:referral_source"])
  end

  it "treats a changed structural fingerprint as drift" do
    reference = scenario_with([["step:intake.1", "x"], ["field:email", "email|identity|required"]])
    candidate = scenario_with([["step:intake.1", "x"], ["field:email", "text|identity|optional"]])

    expect(analyse(candidate, reference, "application_execution")[:drift][:changed]).to eq(["field:email"])
  end
end
