# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: reference_scenarios
#
#  id          :bigint           not null, primary key
#  provider    :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  scenario_id :bigint           not null
#
# Indexes
#
#  index_reference_scenarios_on_provider     (provider) UNIQUE
#  index_reference_scenarios_on_scenario_id  (scenario_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (scenario_id => scenarios.id)
#
RSpec.describe ReferenceScenario do
  subject(:reference_scenario) { build(:reference_scenario, scenario: scenario) }

  let(:scenario) { build(:scenario) }

  it { is_expected.to validate_presence_of(:provider) }
  it { is_expected.to validate_uniqueness_of(:provider) }
  it { is_expected.to belong_to(:scenario) }

  it "requires the pointer provider to match the Scenario" do
    reference = build(:reference_scenario, provider: "greenhouse")

    expect(reference).not_to be_valid
    expect(reference.errors[:provider]).to include("must match the Scenario provider")
  end
end
