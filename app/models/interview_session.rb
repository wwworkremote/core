# frozen_string_literal: true

# == Schema Information
#
# Table name: interview_sessions
#
#  id             :bigint           not null, primary key
#  feedback       :text
#  interviewers   :string
#  notes          :text
#  outcome        :string           default("pending"), not null
#  position       :integer
#  scheduled_at   :datetime
#  session_type   :string
#  vibe           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_interview_sessions_on_job_posting_id  (job_posting_id)
#  index_interview_sessions_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
class InterviewSession < ApplicationRecord
  belongs_to :job_posting
  belongs_to :user

  has_many :interview_questions, dependent: :destroy
  has_many_attached :artifacts

  # Predefined session types for the lab
  SESSION_TYPES = %w[Screening Technical System_Design Cultural Management Offer_Negotiation].freeze

  # How a round went. `pending` = not held yet, or held but not dispositioned.
  OUTCOMES = %w[pending advanced rejected no_signal].freeze

  validates :session_type, presence: true
  validates :outcome, inclusion: { in: OUTCOMES }
  # A placeholder round from a seeded process (TASK-147.1) has no date yet --
  # only a round that actually happened needs one.
  validates :scheduled_at, presence: true, unless: :pending?

  scope :ordered, -> { order(:position, :scheduled_at) }

  # Logging an interview session is itself the signal that this application
  # reached the interview stage -- advance the matching UserJobPosting so the
  # homepage's "Interviews" block and the pipeline timeline agree with the
  # Laboratory. Only a scheduled round moves the pipeline: seeding a template
  # of unscheduled placeholders shouldn't. No-op when there's no tracked
  # application or it can't advance (never favorited/applied, already past
  # interview, archived).
  after_create :advance_application_to_interview
  # Booking a date on a seeded placeholder round is the same signal as
  # creating an already-scheduled one.
  after_update :advance_application_to_interview, if: :saved_change_to_scheduled_at?

  def pending?
    outcome == "pending"
  end

  private

  def advance_application_to_interview
    return if scheduled_at.blank?

    UserJobPosting.find_by(user_id:, job_posting_id:)&.record_status_event!("interview")
  end
end
