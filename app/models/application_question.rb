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

  SOURCES = %w[canned ai].freeze
end
