# frozen_string_literal: true

class Avo::Resources::Source < Avo::BaseResource
  self.title = :name
  self.includes = [:origin]

  def fields
    field :id, as: :id
    field :name, as: :text, link_to_record: true
    field :signature, as: :text
    field :origin, as: :belongs_to
    field :job_postings, as: :has_many
  end
end
