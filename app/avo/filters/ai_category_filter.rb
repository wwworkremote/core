# frozen_string_literal: true

module Avo
  module Filters
    class AiCategoryFilter < Avo::Filters::SelectFilter
      self.name = 'AI Category'

      def apply(_request, query, value)
        query.where("data->>'ai_category' = ?", value)
      end

      def options
        # Matches JobBoards::Categorizer::CATEGORIES
        [
          'Software Engineering',
          'Data Science',
          'Product Management',
          'Design',
          'Marketing',
          'Sales',
          'Customer Support',
          'Operations',
          'Other'
        ].index_by(&:itself)
      end
    end
  end
end
