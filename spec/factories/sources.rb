# frozen_string_literal: true

FactoryBot.define do
  factory :source do
    sequence(:signature) { |n| "source-#{n}" }
  end
end
