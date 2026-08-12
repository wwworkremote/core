# frozen_string_literal: true

FactoryBot.define do
  factory :lead do
    sequence(:url) { |n| "https://example.com/jobs/#{n}" }
    provider { "linkedin" }
    sequence(:signature) { |n| "lead-#{n}" }
    found_at { Time.current }
  end
end
