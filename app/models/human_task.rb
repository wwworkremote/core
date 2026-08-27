# frozen_string_literal: true

# == Schema Information
#
# Table name: human_tasks
#
#  id              :bigint           not null, primary key
#  kind            :string           not null
#  payload         :jsonb            not null
#  proposed_by     :string           default("ai"), not null
#  resolution_note :text
#  resolved_at     :datetime
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  job_posting_id  :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_human_tasks_on_job_posting_id                      (job_posting_id)
#  index_human_tasks_on_job_posting_id_and_kind_and_status  (job_posting_id,kind,status)
#  index_human_tasks_on_status                              (status)
#  index_human_tasks_on_user_id                             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
# BPMN "User Task" equivalent: work an automated step (a "Service Task", see
# Pipeline::PersonaRecommender) proposed but only a human can resolve. This is
# the actual "awaiting human" gate -- deliberately its own table rather than
# an AASM state on UserJobPosting, since several can be open on one posting at
# once (three unanswered application questions, a persona pick, a resume
# review), which a single state column can't represent.
class HumanTask < ApplicationRecord
  include AASM

  belongs_to :job_posting
  belongs_to :user

  KINDS = %w[persona_review question_answer resume_review submit_approval].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :payload, presence: true

  aasm column: :status do
    state :pending, initial: true
    state :approved, :rejected, :edited

    event :approve do
      after { touch_resolved }
      transitions from: :pending, to: :approved
    end

    event :reject do
      after { touch_resolved }
      transitions from: :pending, to: :rejected
    end

    # Human changed the AI's proposal rather than accepting or rejecting it
    # outright -- e.g. edited a drafted answer before it's used. `resolution`
    # holds the human's final version; `payload` keeps the original proposal
    # for comparison.
    event :edit do
      after { touch_resolved }
      transitions from: :pending, to: :edited
    end
  end

  # 24 hours, matching the BPMN 2.0 by Example spec's Travel Booking pattern
  # (a Timer Intermediate Event escalates an unanswered human decision after
  # a fixed delay) -- AASM has no timer/escalation primitive of its own, so
  # this is a plain attribute check a view or scheduled job can act on, not
  # a state. No notification channel exists yet to page Mike about this
  # (no email/Slack/push wired up here), so today this only drives visual
  # escalation in the inbox view -- see TASK-97 for the deferred "actually
  # nudge someone" follow-on.
  STALE_AFTER = 24.hours

  scope :open, -> { where(status: "pending") }
  scope :stale, -> { open.where(created_at: ..STALE_AFTER.ago) }

  def stale?
    pending? && created_at <= STALE_AFTER.ago
  end

  private

  def touch_resolved
    update_column(:resolved_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
