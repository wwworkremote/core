# frozen_string_literal: true

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
