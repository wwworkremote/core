# frozen_string_literal: true

FactoryBot.define do
  factory :domain do
    sequence(:name) { |n| "test-domain-#{n}.com" }
  end
end
