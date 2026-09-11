# frozen_string_literal: true

# One immutable run of Scenarios::DriftAnalysis for a guided session against its
# provider Reference Scenario (ADR 009). Every attempt is recorded, including
# `no_reference` and `failed` -- operational diagnosis matters. Advisory only:
# nothing here authorizes, blocks, or advances an application.
#
# `coverage` is a versioned snapshot of the run's coverage result, not a
# canonical process model. `provider` and `reference_scenario_id` are retained
# as run-time facts alongside the association.
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
class ReferenceComparison < ApplicationRecord
  OUTCOMES = %w[ok no_reference failed].freeze
  TRIGGERS = %w[automatic manual].freeze

  belongs_to :guided_session
  belongs_to :scenario
  belongs_to :reference_scenario, optional: true
  has_many :comparison_findings, dependent: :destroy

  validates :provider, :comparison_rules_version, :ran_at, presence: true
  validates :outcome, inclusion: { in: OUTCOMES }
  validates :trigger, inclusion: { in: TRIGGERS }

  before_validation :set_ran_at, on: :create

  # Immutable after creation.
  def readonly? = persisted?

  private

  def set_ran_at
    self.ran_at ||= Time.current
  end
end
