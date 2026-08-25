# frozen_string_literal: true

# Append-only semantic association between an ATS field and a WWWorkRemote
# source. A new mapping is an observation, not a destructive correction; the
# history lets later tooling learn which labels and page contexts are stable.
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
#  idx_app_field_mappings_on_application_field_semantic     (user_job_posting_id,field_key,semantic_key)
#  idx_on_application_field_answer_id_bd595d0770            (application_field_answer_id)
#  index_application_field_mappings_on_trace_id             (trace_id)
#  index_application_field_mappings_on_user_job_posting_id  (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (application_field_answer_id => application_field_answers.id)
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
class ApplicationFieldMapping < ApplicationRecord
  belongs_to :user_job_posting
  belongs_to :application_field_answer, optional: true

  validates :field_key, :field_label, :semantic_key, :source_kind, :mapped_at, presence: true
  validates :source_kind, inclusion: { in: %w[profile persona question manual] }
end
