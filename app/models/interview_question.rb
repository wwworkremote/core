# frozen_string_literal: true

# == Schema Information
#
# Table name: interview_questions
#
#  id                   :bigint           not null, primary key
#  answer_text          :text
#  category             :string
#  question_text        :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  interview_session_id :bigint           not null
#
# Indexes
#
#  index_interview_questions_on_interview_session_id  (interview_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (interview_session_id => interview_sessions.id)
#
class InterviewQuestion < ApplicationRecord
  belongs_to :interview_session

  validates :question_text, presence: true

  CATEGORIES = %w[Behavioral Technical Architectural Situational Personal].freeze
end
