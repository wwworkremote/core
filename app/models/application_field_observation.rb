# frozen_string_literal: true

# == Schema Information
#
# Table name: application_field_observations
#
#  id                  :bigint           not null, primary key
#  context             :jsonb            not null
#  field_key           :string           not null
#  field_label         :string           not null
#  field_type          :string           not null
#  normalized_prompt   :string           not null
#  observed_at         :datetime         not null
#  page_step           :string
#  page_url            :string
#  question_kind       :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  persona_id          :string
#  trace_id            :string
#  user_job_posting_id :bigint           not null
#
# Indexes
#
#  idx_app_observations_on_app_and_key                          (user_job_posting_id,field_key) UNIQUE
#  idx_app_observations_on_kind_and_prompt                      (question_kind,normalized_prompt)
#  index_application_field_observations_on_trace_id             (trace_id)
#  index_application_field_observations_on_user_job_posting_id  (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
class ApplicationFieldObservation < ApplicationRecord
  belongs_to :user_job_posting

  validates :field_key, :field_label, :field_type, :question_kind, :normalized_prompt,
            :observed_at, presence: true
end
