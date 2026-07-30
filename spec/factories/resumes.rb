# frozen_string_literal: true

FactoryBot.define do
  factory :resume do
    user
    sequence(:name) { |n| "Resume #{n}" }
    version { 1 }
    content { {} }
  end
end
