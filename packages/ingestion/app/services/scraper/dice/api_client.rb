# frozen_string_literal: true

require "nokogiri"

# Service to scrape job listings from Dice.com.
# Uses Playwright to handle client-side rendering and search parameters.
class Scraper::Dice::ApiClient
  BASE_URL = "https://www.dice.com/jobs"

  def self.search(keywords, location: "Remote")
    new.search(keywords, location)
  end

  def call
    # Default search for Ruby/Rails roles
    search("Ruby on Rails", "Remote")
  end

  def search(keywords, location)
    source, query = source_and_query
    fetch_result = fetch_page(search_url(keywords, location))
    return { success: false, error: "Fetch failed" } unless fetch_result

    import(source, query, fetch_result)
  end

  private

  def source_and_query
    source = JobBoards::Source.find_or_create_by!(slug: "dice") { |s| s.name = "Dice" }
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    [source, query]
  end

  def search_url(keywords, location)
    params = { q: keywords, l: location, countryCode: "US", radius: 30, radiusUnit: "mi", page: 1, pageSize: 20 }
    "#{BASE_URL}?#{params.to_query}"
  end

  def fetch_page(url)
    Rails.logger.info "[Dice::ApiClient] Fetching: #{url}"
    JobFetchers::PageFetch.new(url).call
  end

  def import(source, query, fetch_result)
    data = parse_results(fetch_result[:content])
    count = Scraper::DocumentUpserter.call("dice", source, query, data["results"])
    { success: true, count: count }
  end

  def parse_results(html)
    doc = Nokogiri::HTML(html)
    { "results" => doc.css("d-job-card, .card").filter_map { |card| card_fields(card) } }
  end

  def card_fields(card)
    title_link = card.css("a.card-title-link").first
    return unless title_link

    job_id = job_id_from(title_link)
    return unless job_id

    build_result(card, title_link, job_id)
  end

  def job_id_from(title_link)
    title_link["id"] || title_link["href"]&.match(%r{job-detail/([^/?]+)})&.[](1)
  end

  def build_result(card, title_link, job_id)
    base_result(card, title_link).merge("external_id" => job_id, "found_by_terms" => nil)
  end

  def base_result(card, title_link)
    title_fields(title_link).merge(location_fields(card))
  end

  def title_fields(title_link)
    { "jobTitle" => title_link.text.strip, "url" => job_url(title_link) }
  end

  def location_fields(card)
    { "companyName" => company_name(card), "jobGeo" => card.css(".card-location").text.strip }
  end

  def company_name(card)
    card.css('[data-cy="search-result-company-name"], .card-company a').text.strip
  end

  def job_url(title_link)
    href = title_link["href"]
    href.start_with?("http") ? href : "https://www.dice.com#{href}"
  end
end
