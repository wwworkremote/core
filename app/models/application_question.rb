# frozen_string_literal: true

# == Schema Information
#
# Table name: application_questions
#
#  id             :bigint           not null, primary key
#  answer_source  :string
#  answer_text    :text
#  question_text  :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_application_questions_on_job_posting_id  (job_posting_id)
#  index_application_questions_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
class ApplicationQuestion < ApplicationRecord
  belongs_to :job_posting
  belongs_to :user

  validates :question_text, presence: true

  # TASK-113: every manual question is also a durable QuestionOccurrence in the
  # cross-application graph. Non-blocking -- a graph failure never breaks Q&A.
  after_create_commit :record_question_occurrence

  def record_question_occurrence
    QuestionOccurrences::Record.call(self)
  rescue StandardError => e
    Rails.logger.warn "[QuestionOccurrences] #{e.class}: #{e.message}"
  end

  # `submitted` is what the user actually typed into the ATS form, captured by
  # the extension when they mark the application applied. It outranks the
  # other two as future reference material: it's the answer that really went
  # out, not the one that was offered.
  SOURCES = %w[canned ai submitted].freeze
end
