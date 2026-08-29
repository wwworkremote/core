# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::SandboxReferenceWalkthrough do
  subject(:scenario) { described_class.call }

  it "promotes a greenhouse ReferenceScenario from the walkthrough" do
    expect(scenario.provider).to eq("greenhouse")
    expect(ReferenceScenario.find_by(provider: "greenhouse")&.scenario).to eq(scenario)
  end

  it "carries step markers on both sides of the first commitment boundary" do
    kinds = scenario.scenario_signatures.order(:first_observed_at, :id).pluck(:kind)
    boundary_index = kinds.index { |k| k.start_with?("commitment_boundary:") }
    step_indices = kinds.each_index.select { |i| kinds[i].start_with?("step:") }

    expect(boundary_index).not_to be_nil
    expect(step_indices.min).to be < boundary_index
    expect(step_indices.max).to be > boundary_index
  end

  it "carries the field and screening_question markers from the sandbox form" do
    kinds = scenario.scenario_signatures.pluck(:kind)

    expect(kinds).to include("field:first_name", "field:last_name", "field:email", "field:8")
    expect(kinds.count { |k| k.start_with?("screening_question:v1:") }).to eq(2)
  end

  it "carries the ATS identity signatures" do
    observed = Scenarios::HandshakeCheck.call(scenario).filter_map { |r| r[:kind] if r[:present] }

    expect(observed).to include("job_post_id", "ats_application_id")
  end

  it "re-running replaces the reference in place, not accumulating rows" do
    scenario
    second = described_class.call

    expect(ReferenceScenario.where(provider: "greenhouse").count).to eq(1)
    expect(ReferenceScenario.find_by(provider: "greenhouse").scenario).to eq(second)
  end
end
