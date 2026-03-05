# frozen_string_literal: true

class Avo::Resources::JobBoardsDocument < Avo::BaseResource
  self.title = :signature
  self.model_class = ::JobBoards::Document

  def fields
    field :id, as: :id
    field :signature, as: :text, link_to_record: true
    field :document, as: :code, language: 'json'
    field :job_boards_source, as: :belongs_to
    field :job_boards_query, as: :belongs_to
  end
end
