# frozen_string_literal: true

FactoryBot.define do
  factory :scenario do
    provider { "linkedin" }
    started_at { Time.current }
  end
end
