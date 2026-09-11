# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: finding_dispositions
#
#  id                    :bigint           not null, primary key
#  rationale             :text
#  reviewer              :string           not null
#  reviewer_label        :string
#  value                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  comparison_finding_id :bigint           not null
#  resume_persona_id     :string
#  source_disposition_id :bigint
#
# Indexes
#
#  idx_on_comparison_finding_id_created_at_e63111e63f   (comparison_finding_id,created_at)
#  index_finding_dispositions_on_comparison_finding_id  (comparison_finding_id)
#
# Foreign Keys
#
#  fk_rails_...  (comparison_finding_id => comparison_findings.id)
#
RSpec.describe FindingDisposition do
  it "rejects a value outside the five dispositions" do
    expect(build(:finding_disposition, value: "meh")).not_to be_valid
  end

  it "requires a reviewer" do
    expect(build(:finding_disposition, reviewer: nil)).not_to be_valid
  end

  it "is append-only: a later disposition never mutates an earlier one" do
    finding = create(:comparison_finding)
    earlier = finding.finding_dispositions.create!(value: "unresolved", reviewer: "mike", rationale: "first pass")
    finding.finding_dispositions.create!(value: "provider_site_drift", reviewer: "mike")

    expect(earlier.reload).to have_attributes(value: "unresolved", rationale: "first pass")
    expect { earlier.update!(value: "unresolved") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  describe ".latest_for" do
    let(:reference) { create(:reference_scenario, scenario: create(:scenario, provider: "greenhouse")) }

    def disposition(provider:, reference_scenario:, value: "provider_site_drift")
      comparison = create(:reference_comparison, provider: provider, reference_scenario: reference_scenario)
      finding = comparison.comparison_findings.create!(category: "drift", dimension: "field", locator: "field:email")
      finding.finding_dispositions.create!(value: value, reviewer: "mike")
    end

    it "returns the most recent disposition for the same (dimension, locator, provider, reference)" do
      disposition(provider: "greenhouse", reference_scenario: reference, value: "unresolved")
      newest = disposition(provider: "greenhouse", reference_scenario: reference, value: "expected_persona_variation")

      found = described_class.latest_for(dimension: "field", locator: "field:email",
                                         provider: "greenhouse", reference_scenario_id: reference.id)

      expect(found).to eq(newest)
    end

    it "does not cross provider or reference lineage" do
      other_reference = create(:reference_scenario, scenario: create(:scenario, provider: "lever"))
      disposition(provider: "lever", reference_scenario: other_reference)

      found = described_class.latest_for(dimension: "field", locator: "field:email",
                                         provider: "greenhouse", reference_scenario_id: reference.id)

      expect(found).to be_nil
    end
  end
end
