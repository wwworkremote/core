# frozen_string_literal: true

require "nokogiri"

# Service object to scrape job listings from Indeed using Playwright.
# It handles search execution and parsing of job cards into Document records.
class Scraper::Indeed::ApiClient
  prepend Scraper::Traceable

  # Indeed uses a more complex URL structure for search
  BASE_URL = "https://www.indeed.com/jobs"

  # Convenience method to search for jobs.
  # @param query [String] The job title or keywords to search for.
  # @param location [String] The geographic location for the search.
  # @return [Hash] Success status and count of processed documents.
  def self.search(query, location: "Remote")
    new.search(query, location)
  end

  # Default entry point for DataAcquisitionManager.
  # @return [Hash] Success status and count of processed documents.
  def call
    # Default search if called without arguments via DataAcquisitionManager
    search("Staff Engineer", "Remote")
  end

  # Performs the actual search and parsing.
  # @param query_text [String]
  # @param location [String]
  # @return [Hash]
  def search(query_text, location)
    fetch_result = JobFetchers::PageFetch.new(search_url(query_text, location)).call
    return { success: false, error: "Fetch failed" } unless fetch_result

    { success: true, count: import_results(fetch_result[:content]) }
  end

  private

  def search_url(query_text, location)
    params = { q: query_text, l: location, from: "searchOnHP" }
    url = "#{BASE_URL}?#{params.to_query}"
    Rails.logger.info "[Indeed::ApiClient] Fetching: #{url}"
    url
  end

  def import_results(html)
    source = JobBoards::Source.find_by(slug: "indeed")
    query = JobBoards::Query.find_by(source_id: source&.id)
    Scraper::DocumentImporter.call("indeed", source, query, parse_results(html))
  end

  def parse_results(html)
    Nokogiri::HTML(html).css("div.job_seen_beacon").filter_map { |card| parse_card(card) }
  end

  def parse_card(card)
    title_link = card.css("h2.jobTitle a").first
    return nil unless title_link

    card_fields(card, title_link)
  end

  def card_fields(card, title_link)
    job_key = title_link["data-jk"]
    text_fields(card, title_link).merge(
      "url" => "https://www.indeed.com/viewjob?jk=#{job_key}", "external_id" => job_key, "found_by_terms" => nil
    )
  end

  def text_fields(card, title_link)
    {
      "jobTitle" => title_link.text.strip,
      "companyName" => card.css('span[data-testid="company-name"]').text.strip,
      "jobGeo" => card.css('div[data-testid="text-location"]').text.strip
    }
  end
end
