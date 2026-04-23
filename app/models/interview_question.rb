# frozen_string_literal: true

class InterviewQuestion < ApplicationRecord
  belongs_to :interview_session
  
  validates :question_text, presence: true

  CATEGORIES = %w[Behavioral Technical Architectural Situational Personal].freeze
end
