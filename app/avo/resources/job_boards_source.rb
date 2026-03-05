# frozen_string_literal: true

class Avo::Resources::JobBoardsSource < Avo::BaseResource
  self.title = :name
  self.model_class = ::JobBoards::Source

  def fields
    field :id, as: :id
    field :name, as: :text, link_to_record: true
    field :slug, as: :text
    field :data, as: :code
    field :aasm_state, as: :badge
    field :job_boards_queries, as: :has_many
    field :job_boards_documents, as: :has_many
  end
end
