# frozen_string_literal: true

# == Schema Information
#
# Table name: application_field_mappings
#
#  id                          :bigint           not null, primary key
#  context                     :jsonb            not null
#  element_descriptor          :jsonb            not null
#  element_fingerprint         :string
#  field_key                   :string           not null
#  field_label                 :string           not null
#  guided_session_token        :string
#  mapped_at                   :datetime         not null
#  page_step                   :string
#  page_title                  :string
#  page_url                    :string
#  provider                    :string
#  semantic_key                :string           not null
#  semantic_label              :string
#  source_kind                 :string           not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  application_field_answer_id :bigint
#  trace_id                    :string
#  user_job_posting_id         :bigint           not null
#
# Indexes
#
#  idx_app_field_mappings_on_application_field_semantic      (user_job_posting_id,field_key,semantic_key)
#  idx_on_application_field_answer_id_bd595d0770             (application_field_answer_id)
#  index_application_field_mappings_on_guided_session_token  (guided_session_token)
#  index_application_field_mappings_on_trace_id              (trace_id)
#  index_application_field_mappings_on_user_job_posting_id   (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (application_field_answer_id => application_field_answers.id)
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
FactoryBot.define do
  factory :application_field_mapping do
    user_job_posting
    field_key { "workday:email:0" }
    field_label { "Email" }
    semantic_key { "profile.email" }
    semantic_label { "Personal email" }
    source_kind { "profile" }
    provider { "workday" }
    page_step { "My Information" }
    page_url { "https://example.workday.com/apply" }
    page_title { "Application" }
    element_descriptor { { "tag" => "input", "label" => "Email" } }
    context { { "required" => true } }
    mapped_at { Time.current }
  end
end
