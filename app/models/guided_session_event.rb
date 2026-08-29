# frozen_string_literal: true

# One meaningful transition in a GuidedSession. This deliberately records
# intent and safety classification alongside the observable browser evidence.
# == Schema Information
#
# Table name: guided_session_events
#
#  id                :bigint           not null, primary key
#  action            :string           not null
#  approval_state    :string           not null
#  evidence          :jsonb            not null
#  intent            :text             not null
#  kind              :string           not null
#  occurred_at       :datetime         not null
#  page_url          :string
#  phase             :string           not null
#  requirement       :string           not null
#  reversibility     :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  guided_session_id :bigint           not null
#
# Indexes
#
#  idx_on_guided_session_id_occurred_at_296f9f4e6b   (guided_session_id,occurred_at)
#  index_guided_session_events_on_guided_session_id  (guided_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (guided_session_id => guided_sessions.id)
#
class GuidedSessionEvent < ApplicationRecord
  REQUIREMENTS = %w[required optional recommended].freeze
  REVERSIBILITIES = %w[reversible irreversible].freeze
  APPROVAL_STATES = %w[not_required pending approved denied].freeze

  belongs_to :guided_session

  validates :phase, :kind, :action, :intent, :requirement, :reversibility,
            :approval_state, :occurred_at, presence: true
  validates :phase, inclusion: { in: GuidedSession::PHASES }
  validates :requirement, inclusion: { in: REQUIREMENTS }
  validates :reversibility, inclusion: { in: REVERSIBILITIES }
  validates :approval_state, inclusion: { in: APPROVAL_STATES }
  validate :irreversible_transition_requires_approval

  before_validation :set_defaults, on: :create
  # An event that a materialized ScenarioSignature points at is provenance --
  # it cannot be pruned while the reference exists (ADR 009). This also blocks
  # the GuidedSession dependent: :destroy cascade for such a session.
  before_destroy :protect_materialized_provenance

  private

  def protect_materialized_provenance
    return unless ScenarioSignature.exists?(["source ->> 'guided_session_event_id' = ?", id.to_s])

    errors.add(:base, "referenced by a materialized ScenarioSignature")
    throw :abort
  end

  def set_defaults
    self.phase ||= guided_session.phase
    self.occurred_at ||= Time.current
    self.evidence ||= {}
  end

  def irreversible_transition_requires_approval
    return unless reversibility == "irreversible" && approval_state == "not_required"

    errors.add(:approval_state, "must be pending, approved, or denied for irreversible transitions")
  end
end
