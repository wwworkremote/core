# frozen_string_literal: true

require "nokogiri"

class Scraper::LinkedIn::ApiClient
  # LinkedIn guest search URL
  BASE_URL = "https://www.linkedin.com/jobs/search"

  def self.search(keywords, location: "Remote")
    new.search(keywords, location)
  end

  def call
    # Default search if called without arguments via DataAcquisitionManager
    search("Staff Ruby Engineer", "Remote")
  end

  def search(keywords, location)
    fetch_result = JobFetchers::PageFetch.new(search_url(keywords, location)).call
    return { success: false, error: "Fetch failed" } unless fetch_result

    { success: true, count: import_results(fetch_result[:content]) }
  end

  private

  def import_results(html)
    source = JobBoards::Source.find_by(slug: "linkedin")
    query = JobBoards::Query.find_by(source_id: source&.id)
    Scraper::DocumentImporter.call("linkedin", source, query, parse_results(html))
  end

  def search_url(keywords, location)
    params = { keywords: keywords, location: location, f_WT: 2 } # f_WT: Remote filter
    url = "#{BASE_URL}?#{params.to_query}"
    Rails.logger.info "[LinkedIn::ApiClient] Fetching: #{url}"
    url
  end

  # LinkedIn guest search result cards
  def parse_results(html)
    Nokogiri::HTML(html).css(".base-card").filter_map { |card| parse_card(card) }
  end

  def parse_card(card)
    title_link = card.css("a.base-card__full-link").first
    return nil unless title_link

    card_fields(card).merge(href_fields(title_link["href"]))
  end

  def card_fields(card)
    {
      "jobTitle" => card.css(".base-search-card__title").text.strip,
      "companyName" => card.css(".base-search-card__subtitle").text.strip,
      "jobGeo" => card.css(".job-search-card__location").text.strip
    }
  end

  def href_fields(href)
    { "url" => href.split("?").first, "external_id" => job_id_from(href), "found_by_terms" => nil } # Clean URL
  end

  def job_id_from(href)
    numeric_match = href.match(%r{view/(\d+)})
    return numeric_match[1] if numeric_match

    slug_match = href.match(%r{/view/(\w+-\w+|(\d+))})
    (slug_match && slug_match[0].split("-").last) || Digest::MD5.hexdigest(href)[0..10]
  end
end
