# frozen_string_literal: true

FactoryBot.define do
  factory :application_field_observation do
    user_job_posting
    sequence(:field_key) { |n| "field-#{n}" }
    field_label { "Field" }
    field_type { "text" }
    question_kind { "freeform" }
    normalized_prompt { field_label.to_s.downcase }
    observed_at { Time.current }
  end
end
