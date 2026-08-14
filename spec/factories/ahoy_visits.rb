# frozen_string_literal: true

FactoryBot.define do
  factory :ahoy_visit, class: "Ahoy::Visit" do
    sequence(:visit_token) { |n| "visit-token-#{n}" }
    sequence(:visitor_token) { |n| "visitor-token-#{n}" }
    started_at { Time.current }
  end
end
