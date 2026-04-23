# frozen_string_literal: true

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
