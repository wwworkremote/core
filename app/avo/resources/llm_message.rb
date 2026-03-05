# frozen_string_literal: true

class Avo::Resources::LlmMessage < Avo::BaseResource
  self.title = :role
  self.model_class = ::LlmMessage

  def fields
    field :id, as: :id
    field :role, as: :text
    field :content, as: :textarea
    field :llm_chat, as: :belongs_to
    field :model, as: :belongs_to
    field :input_tokens, as: :number
    field :output_tokens, as: :number
    field :created_at, as: :date_time
  end
end
