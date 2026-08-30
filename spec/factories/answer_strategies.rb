# frozen_string_literal: true

FactoryBot.define do
  factory :answer_strategy do
    question_archetype
    answer_text { "Because the mission resonates with my background." }
    source { "authored" }
    sophistication { "authored" }
  end
end
