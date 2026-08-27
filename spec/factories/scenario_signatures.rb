# frozen_string_literal: true

FactoryBot.define do
  factory :scenario_signature do
    scenario
    kind { "job_id" }
    sequence(:value) { |n| "value-#{n}" }
    first_observed_at { Time.current }
  end
end
