# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: scenario_signatures
#
#  id                :bigint           not null, primary key
#  first_observed_at :datetime         not null
#  kind              :string           not null
#  step              :string
#  value             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  scenario_id       :bigint           not null
#
# Indexes
#
#  idx_scenario_signatures_uniq              (scenario_id,kind,value) UNIQUE
#  index_scenario_signatures_on_scenario_id  (scenario_id)
#
# Foreign Keys
#
#  fk_rails_...  (scenario_id => scenarios.id)
#
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
