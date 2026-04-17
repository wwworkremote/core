# frozen_string_literal: true

module Avo
  module Resources
    class JobBoardsQuery < Avo::BaseResource
      self.title = :id
      self.model_class = ::JobBoards::Query
      self.includes = [:job_boards_source]

      def fields
        field :id, as: :id
        field :job_boards_source, as: :belongs_to, name: 'Source'

        # Allow tuning terms/boards directly via KeyValue for flexibility
        field :data, as: :key_value, name: 'Tuning Data'

        field :job_boards_documents, as: :has_many, name: 'Raw Documents'
      end
    end
  end
end
