# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::Coverage do
  let(:reference) do
    scenario_with([
                    ["step:intake.1", "page_arrived"],
                    ["step:resolution.1", "application_page_arrived"],
                    ["commitment_boundary:submit", "pending"],
                    ["step:reorientation.1", "submission_attempted"]
                  ])
  end

  def call(candidate, purpose)
    described_class.call(candidate, reference: reference, purpose: purpose)
  end

  it "counts every step checkpoint for an application_execution session" do
    candidate = scenario_with([["step:intake.1", "x"], ["step:resolution.1", "x"]])

    result = call(candidate, "application_execution")

    expect(result[:applicable]).to eq(3)
    expect(result[:reached]).to eq(2)
    expect(result[:ratio]).to eq(2.0 / 3)
    expect(result[:status]).to eq("available")
  end

  it "renders a per-checkpoint reached / not_reached map" do
    candidate = scenario_with([["step:intake.1", "x"]])

    statuses = call(candidate, "application_execution")[:checkpoints].map { |c| c.values_at(:kind, :status) }

    expect(statuses).to eq([
                             ["step:intake.1", "reached"],
                             ["step:resolution.1", "not_reached"],
                             ["step:reorientation.1", "not_reached"]
                           ])
  end

  it "marks checkpoints past the first commitment boundary not_applicable for research" do
    candidate = scenario_with([["step:intake.1", "x"], ["step:resolution.1", "x"]])

    result = call(candidate, "application_research")
    reorientation = result[:checkpoints].find { |c| c[:kind] == "step:reorientation.1" }

    expect(reorientation[:status]).to eq("not_applicable")
    expect(result[:applicable]).to eq(2)
    expect(result[:reached]).to eq(2)
    expect(result[:ratio]).to eq(1.0)
  end

  it "reports unavailable when the reference has no applicable checkpoints" do
    stepless_reference = scenario_with([%w[job_post_id 123]])
    candidate = scenario_with([%w[job_post_id 123]])

    result = described_class.call(candidate, reference: stepless_reference, purpose: "application_execution")

    expect(result[:status]).to eq("unavailable")
    expect(result[:ratio]).to be_nil
  end
end
