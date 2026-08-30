# frozen_string_literal: true

# == Schema Information
#
# Table name: question_occurrences
#
#  id                         :bigint           not null, primary key
#  archetype_assigned_by      :string
#  archetype_confidence       :integer
#  context                    :jsonb            not null
#  datalake_extractor_version :string
#  field_key                  :string
#  normalized_prompt          :string           not null
#  observed_at                :datetime         not null
#  page_step                  :string
#  provider                   :string
#  question_kind              :string           not null
#  raw_prompt                 :text             not null
#  source_kind                :string           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  guided_session_id          :bigint
#  job_posting_id             :bigint           not null
#  persona_id                 :string
#  question_archetype_id      :bigint
#  user_id                    :bigint           not null
#  user_job_posting_id        :bigint
#
# Indexes
#
#  idx_question_occurrences_dedupe                      (user_job_posting_id,field_key,normalized_prompt,source_kind) UNIQUE
#  index_question_occurrences_on_guided_session_id      (guided_session_id)
#  index_question_occurrences_on_job_posting_id         (job_posting_id)
#  index_question_occurrences_on_normalized_prompt      (normalized_prompt)
#  index_question_occurrences_on_question_archetype_id  (question_archetype_id)
#  index_question_occurrences_on_user_id                (user_id)
#  index_question_occurrences_on_user_job_posting_id    (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (guided_session_id => guided_sessions.id)
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (question_archetype_id => question_archetypes.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
FactoryBot.define do
  factory :question_occurrence do
    job_posting
    user
    provider { "greenhouse" }
    raw_prompt { "Why do you want to work here?" }
    normalized_prompt { "why do you want to work here" }
    question_kind { "motivation" }
    source_kind { "observed" }
    observed_at { Time.current }
  end
end
