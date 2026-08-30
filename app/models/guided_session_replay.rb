# frozen_string_literal: true

# A supervised replay of a completed GuidedSession (TASK-133). Re-fills known
# fields from the recorded answers, one confirmed step at a time, and stops at
# every ReplayPlan gate. It NEVER clicks Next / Continue / Submit -- every
# navigation or transmission stays a human action (Bounded Agency). Approving
# a gate ends the replay; it never resumes provider action past a boundary.
class GuidedSessionReplay < ApplicationRecord
  STATUSES = %w[running paused_at_gate stopped completed].freeze

  belongs_to :guided_session

  validates :status, inclusion: { in: STATUSES }
  validates :current_step, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  before_validation { self.started_at ||= Time.current }

  scope :active, -> { where(status: %w[running paused_at_gate]) }

  def active? = %w[running paused_at_gate].include?(status)

  def ended? = %w[stopped completed].include?(status)
end
