# frozen_string_literal: true

# == Schema Information
#
# Table name: models
#
#  id                :bigint           not null, primary key
#  capabilities      :jsonb
#  context_window    :integer
#  family            :string
#  knowledge_cutoff  :date
#  max_output_tokens :integer
#  metadata          :jsonb
#  modalities        :jsonb
#  model_created_at  :datetime
#  name              :string           not null
#  pricing           :jsonb
#  provider          :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  model_id          :string           not null
#
# Indexes
#
#  index_models_on_capabilities           (capabilities) USING gin
#  index_models_on_family                 (family)
#  index_models_on_modalities             (modalities) USING gin
#  index_models_on_provider_and_model_id  (provider,model_id) UNIQUE
#
FactoryBot.define do
  factory :model do
    model_id { "llama3.2:latest" }
    name { "Llama 3.2 Local" }
    provider { "ollama" }
    capabilities { %w[chat embeddings] }
  end
end
