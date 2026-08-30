# frozen_string_literal: true

FactoryBot.define do
  factory :question_archetype do
    sequence(:label) { |n| "Archetype #{n}" }
    canonical_prompt { "why do you want to work here" }
    question_kind { "motivation" }
  end
end
