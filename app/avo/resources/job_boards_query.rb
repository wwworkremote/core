# frozen_string_literal: true

class Avo::Resources::JobBoardsQuery < Avo::BaseResource
  self.title = :id
  self.model_class = ::JobBoards::Query

  def fields
    field :id, as: :id
    field :job_boards_source, as: :belongs_to
    field :job_boards_documents, as: :has_many
  end
end
