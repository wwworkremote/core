# frozen_string_literal: true

# A supervised replay of a completed GuidedSession (TASK-133). Re-fills known
# fields from the recorded answers, one confirmed step at a time, and stops at
# every ReplayPlan gate. It NEVER clicks Next / Continue / Submit -- every
# navigation or transmission stays a human action (Bounded Agency). Approving
# a gate ends the replay; it never resumes provider action past a boundary.
# == Schema Information
#
# Table name: guided_session_replays
#
#  id                :bigint           not null, primary key
#  allow_real_site   :boolean          default(FALSE), not null
#  current_step      :integer          default(0), not null
#  ended_at          :datetime
#  ended_reason      :string
#  started_at        :datetime         not null
#  status            :string           default("running"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  guided_session_id :bigint           not null
#
# Indexes
#
#  index_guided_session_replays_on_guided_session_id             (guided_session_id)
#  index_guided_session_replays_on_guided_session_id_and_status  (guided_session_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (guided_session_id => guided_sessions.id)
#
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
