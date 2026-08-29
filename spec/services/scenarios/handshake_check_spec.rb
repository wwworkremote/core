# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::HandshakeCheck do
  describe "#call" do
    it "reports required-and-present when the expected signature was observed" do
      scenario = create(:scenario, provider: "linkedin")
      create(:scenario_signature, scenario: scenario, kind: "job_id", value: "12345")

      result = described_class.call(scenario)

      expect(result).to contain_exactly(
        { kind: "job_id", requirement: :required, present: true, status: "required-and-present" }
      )
    end

    it "reports required-and-missing when the expected signature was never observed -- the real finding" do
      scenario = create(:scenario, provider: "linkedin")

      result = described_class.call(scenario)

      expect(result).to contain_exactly(
        { kind: "job_id", requirement: :required, present: false, status: "required-and-missing" }
      )
    end

    it "reports optional-and-missing as expected, not a problem" do
      scenario = create(:scenario, provider: "workday")

      result = described_class.call(scenario)

      candidate_id = result.find { |r| r[:kind] == "candidate_id" }
      expect(candidate_id).to include(status: "optional-and-missing")
    end

    it "reports optional-and-present" do
      scenario = create(:scenario, provider: "workday")
      create(:scenario_signature, scenario: scenario, kind: "candidate_id", value: "abc")

      result = described_class.call(scenario)

      candidate_id = result.find { |r| r[:kind] == "candidate_id" }
      expect(candidate_id).to include(status: "optional-and-present")
    end

    describe "step-aware required_after_submit (ADR 009)" do
      def ats_status(scenario, purpose: nil)
        described_class.call(scenario, purpose: purpose)
                       .find { |r| r[:kind] == "ats_application_id" }[:status]
      end

      it "is required-and-present when the post-submit signature was observed" do
        scenario = create(:scenario, provider: "greenhouse")
        create(:scenario_signature, scenario: scenario, kind: "commitment_boundary:submit", value: "pending")
        create(:scenario_signature, scenario: scenario, kind: "ats_application_id", value: "app_1")

        expect(ats_status(scenario)).to eq("required-and-present")
      end

      it "is required-and-missing (drift) when a boundary was reached but the signature is absent" do
        scenario = create(:scenario, provider: "greenhouse")
        create(:scenario_signature, scenario: scenario, kind: "commitment_boundary:submit", value: "pending")

        expect(ats_status(scenario)).to eq("required-and-missing")
      end

      it "is missing-step-not-reached (coverage info) when no boundary was reached" do
        scenario = create(:scenario, provider: "greenhouse")

        expect(ats_status(scenario)).to eq("missing-step-not-reached")
      end

      it "is not-applicable-to-purpose for a research session that stopped before the boundary" do
        scenario = create(:scenario, provider: "greenhouse")

        expect(ats_status(scenario, purpose: "application_research")).to eq("not-applicable-to-purpose")
      end
    end

    it "returns no results for a provider with no configured expectations" do
      scenario = create(:scenario, provider: "unknown_board")

      expect(described_class.call(scenario)).to eq([])
    end
  end
end
