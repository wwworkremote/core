# frozen_string_literal: true

# Handles the "no fetcher class, discover jobs by crawling" strategy for
# DataAcquisitionManager.run -- one of its three run_* dispatch targets,
# split out alongside ServiceRunner to keep DataAcquisitionManager itself
# under Metrics/ClassLength.
class DataAcquisitionManager::CrawlRunner
  def self.call(slug, config)
    queries = BoardQuery.where(board_name: slug.downcase)
    return enqueue_crawls(queries, slug, config) if queries.any?

    enqueue_default_crawl(slug, config)
  end

  def self.enqueue_crawls(queries, slug, config)
    queries.each { |q| enqueue_crawl_query(q, slug, config) }
    { success: true }
  end

  def self.enqueue_crawl_query(query, slug, config)
    url = query.build_url || query.query_params["start_url"]
    return if url.blank?

    selector = query.query_params["selector"] || DataAcquisitionManager::CrawlDefaults::SELECTOR
    config[:class].perform_later(slug, url, selector)
  end

  def self.enqueue_default_crawl(slug, config)
    default_url = DataAcquisitionManager::CrawlDefaults::URLS[slug]
    return { success: false, error: "No active queries found for #{slug}" } unless default_url

    config[:class].perform_later(slug, default_url, DataAcquisitionManager::CrawlDefaults::SELECTOR)
    { success: true }
  end
end
