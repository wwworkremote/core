# frozen_string_literal: true

FactoryBot.define do
  factory :job_boards_source, class: "JobBoards::Source" do
    sequence(:name) { |n| "Test Board #{n}" }
    sequence(:slug) { |n| "test-board-#{n}" }
  end

  factory :job_boards_query, class: "JobBoards::Query" do
    job_boards_source
  end

  factory :job_boards_document, class: "JobBoards::Document" do
    job_boards_source
    job_boards_query
    signature { SecureRandom.hex(16) }
    document { { title: "Ruby Dev" }.to_json }
    aasm_state { "pending" }
  end
end
