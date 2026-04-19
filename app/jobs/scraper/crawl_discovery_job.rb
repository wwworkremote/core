class Scraper::CrawlDiscoveryJob < ApplicationJob
  queue_as :default

  def perform(board_name, base_url, selector)
    Scraper::Crawler::Discovery.new(board_name, base_url, selector: selector).call
  end
end
