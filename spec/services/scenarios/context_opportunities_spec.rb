# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::ContextOpportunities do
  it "flags a provider-optional signature this capture never observed" do
    scenario = create(:scenario, provider: "workday")
    create(:scenario_signature, scenario: scenario, kind: "tenant_id", value: "acme")

    opportunities = described_class.call(scenario)

    expect(opportunities.map(&:kind)).to eq(%w[candidate_id])
    expect(opportunities.first.rank).to eq(1)
    expect(opportunities.first.reason).to include("optional")
  end

  it "is empty when every optional signature was observed" do
    scenario = create(:scenario, provider: "workday")
    create(:scenario_signature, scenario: scenario, kind: "tenant_id", value: "acme")
    create(:scenario_signature, scenario: scenario, kind: "candidate_id", value: "c-1")

    expect(described_class.call(scenario)).to be_empty
  end

  it "is empty for a provider with no optional expectations" do
    scenario = create(:scenario, provider: "greenhouse")

    expect(described_class.call(scenario)).to be_empty
  end

  it "flags an observed application field that has no answer-strategy mapping" do
    scenario = create(:scenario, provider: "greenhouse")
    application = create(:user_job_posting)
    create(:application_field_observation, user_job_posting: application, field_key: "why_us", field_label: "Why us?")
    create(:application_field_observation, user_job_posting: application, field_key: "email", field_label: "Email")
    create(:application_field_mapping, user_job_posting: application, field_key: "email")

    opportunities = described_class.call(scenario, user_job_posting: application)

    expect(opportunities.map(&:kind)).to eq(%w[field:why_us])
    expect(opportunities.first.reason).to include("Why us?")
  end
end
