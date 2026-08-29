# frozen_string_literal: true

# Append-only human judgment on a ComparisonFinding (ADR 009). The latest row
# wins for presentation (ComparisonFinding#current_disposition); earlier rows
# are never overwritten and stay first-class records. A row carried in from an
# earlier run's matching finding is only ever a suggested default -- when Mike
# acts on one, `source_disposition_id` records the lineage.
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
class FindingDisposition < ApplicationRecord
  VALUES = %w[
    provider_site_drift reference_incomplete_or_stale expected_persona_variation
    expected_session_purpose_variation unresolved
  ].freeze

  belongs_to :comparison_finding
  belongs_to :source_disposition, class_name: "FindingDisposition", optional: true

  validates :value, inclusion: { in: VALUES }
  validates :reviewer, presence: true

  # Append-only: existing rows never change.
  def readonly? = persisted?

  # The carry-forward lookup: the most recent disposition for the same
  # (dimension, locator) on the same provider + reference lineage.
  def self.latest_for(dimension:, locator:, provider:, reference_scenario_id:)
    joins(comparison_finding: :reference_comparison)
      .where(comparison_findings: { dimension: dimension, locator: locator })
      .where(reference_comparisons: { provider: provider, reference_scenario_id: reference_scenario_id })
      .order(created_at: :desc, id: :desc)
      .first
  end
end
