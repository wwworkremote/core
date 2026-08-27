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

    it "checks required_after_submit as plain required for now (documented ceiling)" do
      scenario = create(:scenario, provider: "greenhouse")

      result = described_class.call(scenario)

      ats_application_id = result.find { |r| r[:kind] == "ats_application_id" }
      expect(ats_application_id).to include(requirement: :required_after_submit, status: "required-and-missing")
    end

    it "returns no results for a provider with no configured expectations" do
      scenario = create(:scenario, provider: "unknown_board")

      expect(described_class.call(scenario)).to eq([])
    end
  end
end
