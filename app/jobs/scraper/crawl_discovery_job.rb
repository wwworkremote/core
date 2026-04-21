class Scraper::CrawlDiscoveryJob < ApplicationJob
  queue_as :default
  mediumweight!
  idempotent! ->(board, url, _) { "crawl/#{board}/#{url}" }

  def perform(board_name, base_url, selector)
    return if SystemSetting.paused?
    Scraper::Crawler::Discovery.new(board_name, base_url, selector: selector).call
  end
end
