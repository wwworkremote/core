# frozen_string_literal: true

class Avo::Resources::Origin < Avo::BaseResource
  self.title = :name

  def fields
    field :id, as: :id
    field :name, as: :text
    field :data, as: :code
    field :sources, as: :has_many
  end
end
