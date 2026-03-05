# frozen_string_literal: true

class Avo::Resources::LlmChat < Avo::BaseResource
  self.title = :id
  self.model_class = ::LlmChat

  def fields
    field :id, as: :id
    field :model, as: :belongs_to
    field :llm_messages, as: :has_many
    field :created_at, as: :date_time
  end
end
