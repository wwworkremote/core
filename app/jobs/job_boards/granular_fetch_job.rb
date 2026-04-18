# frozen_string_literal: true

module JobBoards
  class GranularFetchJob < ApplicationJob
    include ApiGuard
    queue_as :default

    def perform(fetcher_class_name, site_slug, term, source_id, query_id)
      fetcher_slug = fetcher_class_name.split('::').first.downcase
      return if source_locked?(fetcher_slug)

      fetcher_class = fetcher_class_name.constantize
      fetcher = fetcher_class.new

      # Execute the specific fetch logic
      # We'll pass the necessary IDs and parameters to a specialized method
      fetcher.fetch_granular(site_slug, term, source_id, query_id)
    end
  end
end
