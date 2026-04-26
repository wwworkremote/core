# frozen_string_literal: true

FactoryBot.define do
  factory :interview_task do
    association :user
    association :job_posting
    title { "Prepare for interview" }
    status { "pending" }
  end
end
