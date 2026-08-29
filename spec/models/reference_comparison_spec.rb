# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: reference_comparisons
#
#  id                       :bigint           not null, primary key
#  comparison_rules_version :string           not null
#  coverage                 :jsonb            not null
#  error                    :string
#  outcome                  :string           not null
#  provider                 :string           not null
#  ran_at                   :datetime         not null
#  trigger                  :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  guided_session_id        :bigint           not null
#  reference_scenario_id    :bigint
#  scenario_id              :bigint           not null
#
# Indexes
#
#  idx_on_provider_reference_scenario_id_e9d8e683d2      (provider,reference_scenario_id)
#  index_reference_comparisons_on_guided_session_id      (guided_session_id)
#  index_reference_comparisons_on_reference_scenario_id  (reference_scenario_id)
#  index_reference_comparisons_on_scenario_id            (scenario_id)
#
# Foreign Keys
#
#  fk_rails_...  (guided_session_id => guided_sessions.id)
#  fk_rails_...  (reference_scenario_id => reference_scenarios.id)
#  fk_rails_...  (scenario_id => scenarios.id)
#
RSpec.describe ReferenceComparison do
  it "defaults ran_at on creation" do
    expect(create(:reference_comparison).ran_at).to be_within(2.seconds).of(Time.current)
  end

  it "is immutable after creation" do
    comparison = create(:reference_comparison)

    expect { comparison.update!(outcome: "failed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "records a run with no reference" do
    comparison = build(:reference_comparison, outcome: "no_reference", reference_scenario: nil)

    expect(comparison).to be_valid
  end

  it "rejects an unknown outcome or trigger" do
    expect(build(:reference_comparison, outcome: "weird")).not_to be_valid
    expect(build(:reference_comparison, trigger: "cron")).not_to be_valid
  end

  it "associates a reference_scenario as a real association" do
    reference = create(:reference_scenario, scenario: create(:scenario, provider: "greenhouse"))
    comparison = create(:reference_comparison, reference_scenario: reference)

    expect(comparison.reference_scenario).to eq(reference)
  end
end
