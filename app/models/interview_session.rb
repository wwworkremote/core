# frozen_string_literal: true

# == Schema Information
#
# Table name: interview_sessions
#
#  id             :bigint           not null, primary key
#  feedback       :text
#  notes          :text
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

  validates :session_type, presence: true
  validates :scheduled_at, presence: true

  # Predefined session types for the lab
  SESSION_TYPES = %w[Screening Technical System_Design Cultural Management Offer_Negotiation].freeze

  # Logging an interview session is itself the signal that this application
  # reached the interview stage -- advance the matching UserJobPosting so the
  # homepage's "Interviews" block and the pipeline timeline agree with the
  # Laboratory. No-op when there's no tracked application or it can't advance
  # (never favorited/applied, already past interview, archived).
  after_create :advance_application_to_interview

  private

  def advance_application_to_interview
    UserJobPosting.find_by(user_id:, job_posting_id:)&.record_status_event!("interview")
  end
end
