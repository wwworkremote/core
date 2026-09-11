# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: comparison_findings
#
#  id                       :bigint           not null, primary key
#  category                 :string           not null
#  detail                   :jsonb            not null
#  dimension                :string           not null
#  locator                  :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  reference_comparison_id  :bigint           not null
#  suggested_disposition_id :bigint
#
# Indexes
#
#  index_comparison_findings_on_dimension_and_locator    (dimension,locator)
#  index_comparison_findings_on_reference_comparison_id  (reference_comparison_id)
#
# Foreign Keys
#
#  fk_rails_...  (reference_comparison_id => reference_comparisons.id)
#
RSpec.describe ComparisonFinding do
  it "is immutable after creation" do
    finding = create(:comparison_finding)

    expect { finding.update!(locator: "field:other") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "rejects an unknown category or dimension" do
    expect(build(:comparison_finding, category: "surprise")).not_to be_valid
    expect(build(:comparison_finding, dimension: "vibes")).not_to be_valid
  end

  describe "#current_disposition" do
    it "is nil until a disposition is recorded" do
      expect(create(:comparison_finding).dispositioned?).to be(false)
    end

    it "returns the latest disposition and keeps the history" do
      finding = create(:comparison_finding)
      first = finding.finding_dispositions.create!(value: "unresolved", reviewer: "mike")
      latest = finding.finding_dispositions.create!(value: "provider_site_drift", reviewer: "mike")

      expect(finding.current_disposition).to eq(latest)
      expect(finding.finding_dispositions.order(:id)).to eq([first, latest])
    end
  end
end
