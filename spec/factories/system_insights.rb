# frozen_string_literal: true

FactoryBot.define do
  factory :system_insight do
    tool { :rubocop }
    severity { :warning }
    message { "RuboCop offense found" }
    file_path { "app/models/user.rb" }
    line_number { 10 }
    active { true }
  end
end
