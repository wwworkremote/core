# frozen_string_literal: true

# One externally-observed identity encountered during a Scenario's capture
# (a LinkedIn job id, a Greenhouse job_post_id, a session cookie...).
# Append-only, same convention ApplicationFieldMapping already uses for its
# own history -- a correction is a new row, not an overwrite, so later
# tooling can see whether an id changed mid-flow rather than only ever
# seeing the last one. #kind is a free string, not a fixed enum: new
# providers introduce new kinds. See docs/architecture/signature-registry.md.
# == Schema Information
#
# Table name: scenario_signatures
#
#  id                :bigint           not null, primary key
#  first_observed_at :datetime         not null
#  kind              :string           not null
#  source            :jsonb
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
class ScenarioSignature < ApplicationRecord
  # #source (nullable) is a value-free provenance breadcrumb for a signature
  # materialized from a guided session -- see Scenarios::GuidedCapture / ADR 009.
  # NULL for the HAR/DOM text path. Only these keys, and extracted_from must be a
  # plain dotted/indexed path (no values, no interpolation).
  SOURCE_KEYS = %w[guided_session_event_id extracted_from].freeze
  SOURCE_PATH = /\A[a-z_]+(\[\d+\])?(\.[a-z_]+(\[\d+\])?)*\z/

  belongs_to :scenario

  validates :kind, :value, :first_observed_at, presence: true
  validates :value, uniqueness: { scope: %i[scenario_id kind] }
  validate :source_keys_allowed
  validate :source_path_safe

  private

  def source_keys_allowed
    return if source.blank? || (source.keys - SOURCE_KEYS).empty?

    errors.add(:source, "has keys outside #{SOURCE_KEYS.join(', ')}")
  end

  def source_path_safe
    path = source && source["extracted_from"]
    return if path.blank? || path.match?(SOURCE_PATH)

    errors.add(:source, "extracted_from is not a plain path")
  end
end
