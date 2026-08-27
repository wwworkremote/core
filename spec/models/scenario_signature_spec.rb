# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScenarioSignature do
  describe "validations" do
    it { is_expected.to validate_presence_of(:kind) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_presence_of(:first_observed_at) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:scenario) }
  end

  it "is append-only per (scenario, kind) -- a changed value is a new row, not an overwrite" do
    scenario = create(:scenario)
    create(:scenario_signature, scenario: scenario, kind: "session_cookie", value: "abc")

    second = build(:scenario_signature, scenario: scenario, kind: "session_cookie", value: "xyz")

    expect(second).to be_valid
    expect { second.save! }.to change(described_class, :count).by(1)
  end

  it "rejects a duplicate (scenario, kind, value)" do
    scenario = create(:scenario)
    create(:scenario_signature, scenario: scenario, kind: "job_id", value: "12345")

    duplicate = build(:scenario_signature, scenario: scenario, kind: "job_id", value: "12345")

    expect(duplicate).not_to be_valid
  end

  it "allows the same value under a different scenario" do
    create(:scenario_signature, kind: "job_id", value: "12345")

    other_scenario_signature = build(:scenario_signature, kind: "job_id", value: "12345")

    expect(other_scenario_signature).to be_valid
  end
end
