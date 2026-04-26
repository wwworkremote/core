# frozen_string_literal: true

FactoryBot.define do
  factory :model do
    model_id { "llama3.2:latest" }
    name { "Llama 3.2 Local" }
    provider { "ollama" }
    capabilities { ["chat", "embeddings"] }
  end
end
