# frozen_string_literal: true

# The last value explicitly provided for one field on one tracked application.
# This is intentionally separate from ApplicationQuestion: most ATS fields are
# not questions, and their provenance needs to survive after the page changes.
# == Schema Information
#
# Table name: application_field_answers
#
#  id                  :bigint           not null, primary key
#  answer              :text             not null
#  answer_source       :string           not null
#  field_key           :string           not null
#  field_label         :string           not null
#  field_type          :string           not null
#  page_url            :string
#  provided_at         :datetime         not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  trace_id            :string
#  user_job_posting_id :bigint           not null
#
# Indexes
#
#  idx_app_fields_on_app_and_key                           (user_job_posting_id,field_key) UNIQUE
#  index_application_field_answers_on_trace_id             (trace_id)
#  index_application_field_answers_on_user_job_posting_id  (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
class ApplicationFieldAnswer < ApplicationRecord
  belongs_to :user_job_posting

  validates :field_key, :field_label, :field_type, :answer, :answer_source, :provided_at, presence: true
  validates :answer_source, inclusion: { in: %w[profile persona template question manual] }
end
