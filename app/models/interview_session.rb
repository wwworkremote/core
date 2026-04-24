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
end
