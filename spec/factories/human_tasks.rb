# frozen_string_literal: true

# == Schema Information
#
# Table name: human_tasks
#
#  id              :bigint           not null, primary key
#  kind            :string           not null
#  payload         :jsonb            not null
#  proposed_by     :string           default("ai"), not null
#  resolution_note :text
#  resolved_at     :datetime
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  job_posting_id  :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_human_tasks_on_job_posting_id                      (job_posting_id)
#  index_human_tasks_on_job_posting_id_and_kind_and_status  (job_posting_id,kind,status)
#  index_human_tasks_on_status                              (status)
#  index_human_tasks_on_user_id                             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :human_task do
    job_posting
    user
    kind { "persona_review" }
    payload { { "persona_id" => "founding_staff_fullstack", "confidence" => 80, "rationale" => "test" } }
  end
end
