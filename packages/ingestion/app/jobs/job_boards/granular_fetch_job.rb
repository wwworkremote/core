# frozen_string_literal: true

class JobBoards::GranularFetchJob < ApplicationJob
  include ApiGuard

  queue_as :light
  mediumweight!

  def perform(fetcher_class_name, site_slug, term, ids)
    fetcher_slug = fetcher_class_name.split("::").first.downcase
    return if source_locked?(fetcher_slug)

    # Execute the specific fetch logic
    fetcher_class_name.constantize.new.fetch_granular(site_slug, term, ids[:source_id], ids[:query_id])
  end
end
