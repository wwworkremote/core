# frozen_string_literal: true

class Avo::Resources::Model < Avo::BaseResource
  self.title = :name
  self.model_class = ::Model

  def fields
    field :id, as: :id
    field :name, as: :text, link_to_record: true
    field :model_id, as: :text
    field :provider, as: :text
    field :family, as: :text
    field :context_window, as: :number
    field :max_output_tokens, as: :number
  end
end
