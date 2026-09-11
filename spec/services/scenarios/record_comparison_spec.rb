# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::RecordComparison do
  subject(:record) { described_class.call(guided_session, trigger: "automatic") }

  let(:guided_session) do
    GuidedSession.create!(source_url: "https://wwworkremote.localhost/sandbox/postings/1",
                          purpose: "application_execution")
  end

  def event(kind, phase, occurred_at, evidence)
    guided_session.guided_session_events.create!(
      kind: kind, phase: phase, action: "act", intent: "map the flow",
      requirement: "recommended", reversibility: "reversible", approval_state: "not_required",
      occurred_at: occurred_at, evidence: evidence
    )
  end

  before do
    event("page_arrived", "intake", 3.minutes.ago, provider: "greenhouse")
    event("application_page_arrived", "resolution", 2.minutes.ago,
          provider: "greenhouse", fields: [
            { field_key: "email", label: "Email", type: "email", classification: "identity", required: true }
          ])
  end

  context "without a reference scenario for the provider" do
    it "records a no_reference run with no findings" do
      expect(record.outcome).to eq("no_reference")
      expect(record.comparison_findings).to be_empty
    end
  end

  context "with a reference scenario" do
    let!(:reference_scenario) do
      ref = create(:scenario, provider: "greenhouse")
      create(:scenario_signature, scenario: ref, kind: "step:intake.1", value: "page_arrived",
                                  first_observed_at: 10.minutes.ago)
      create(:scenario_signature, scenario: ref, kind: "field:phone", value: "tel|identity|required",
                                  first_observed_at: 9.minutes.ago)
      create(:scenario_signature, scenario: ref, kind: "step:resolution.1", value: "application_page_arrived",
                                  first_observed_at: 8.minutes.ago)
      create(:reference_scenario, provider: "greenhouse", scenario: ref)
    end

    it "records an ok run with drift and coverage_gap findings" do
      findings = record.comparison_findings

      expect(record.outcome).to eq("ok")
      expect(record.coverage).to be_present
      expect(findings.map { |f| [f.category, f.dimension, f.locator] }).to include(
        ["drift", "field", "field:phone"],
        ["drift", "field", "field:email"]
      )
    end

    it "attaches a prior disposition as a suggestion without dispositioning the new finding" do
      prior_comparison = create(:reference_comparison, provider: "greenhouse",
                                                       reference_scenario: reference_scenario)
      prior_finding = prior_comparison.comparison_findings.create!(category: "drift", dimension: "field",
                                                                   locator: "field:email")
      prior = prior_finding.finding_dispositions.create!(value: "expected_persona_variation", reviewer: "mike")

      finding = record.comparison_findings.find_by(locator: "field:email")

      expect(finding.suggested_disposition).to eq(prior)
      expect(finding.dispositioned?).to be(false)
    end

    it "does not carry a suggestion across providers" do
      other = create(:reference_comparison, provider: "lever",
                                            reference_scenario: create(:reference_scenario,
                                                                       scenario: create(:scenario, provider: "lever")))
      other_finding = other.comparison_findings.create!(category: "drift", dimension: "field", locator: "field:email")
      other_finding.finding_dispositions.create!(value: "provider_site_drift", reviewer: "mike")

      expect(record.comparison_findings.find_by(locator: "field:email").suggested_disposition).to be_nil
    end
  end
end
