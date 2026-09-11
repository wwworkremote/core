# frozen_string_literal: true

require "nokogiri"

# Service to deep-scrape Glassdoor job listings and associated company intelligence.
class Scraper::Glassdoor::ApiClient
  prepend Scraper::Traceable

  BASE_URL = "https://www.glassdoor.com/Job/jobs.htm"

  def self.search(keywords, location: "Remote")
    new.search(keywords, location)
  end

  def call
    search("Staff Ruby on Rails", "Remote")
  end

  def search(keywords, location)
    source, query = source_and_query
    fetch_result = fetch_page(search_url(keywords, location))
    return { success: false, error: "Fetch failed" } unless fetch_result

    import(source, query, fetch_result)
  end

  private

  def source_and_query
    source = JobBoards::Source.find_or_create_by!(slug: "glassdoor") { |s| s.name = "Glassdoor" }
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    [source, query]
  end

  # NOTE: locId is hardcoded to a fixed Glassdoor region id; `location` is
  # accepted for API-shape parity with the other ApiClients but not yet
  # wired into a real geo lookup -- pre-existing behavior, unchanged here.
  def search_url(keywords, _location)
    "#{BASE_URL}?suggestCount=0&suggestChosen=false&clickSource=searchBtn&typedKeyword=#{keywords}" \
      "&locT=R&locId=110&jobType="
  end

  def fetch_page(url)
    Rails.logger.info "[Glassdoor::ApiClient] Fetching: #{url}"
    JobFetchers::PageFetch.new(url).call
  end

  def import(source, query, fetch_result)
    data = parse_results(fetch_result[:content])
    count = Scraper::DocumentUpserter.call("glassdoor", source, query, data["results"])
    { success: true, count: count }
  end

  def parse_results(html)
    doc = Nokogiri::HTML(html)
    { "results" => doc.css('li[data-test="jobListing"]').filter_map { |card| card_fields(card) } }
  end

  def card_fields(card)
    external_id = card["data-id"]
    return unless external_id

    build_result(card, external_id)
  end

  def build_result(card, external_id)
    base_result(card).merge("external_id" => external_id, "found_by_terms" => nil)
  end

  def base_result(card)
    title_and_company(card).merge(geo_and_rating(card), "url" => job_url(card))
  end

  def title_and_company(card)
    {
      "jobTitle" => card.css('[data-test="job-title"]').text.strip,
      "companyName" => card.css('[data-test="employer-short-name"]').text.strip
    }
  end

  def geo_and_rating(card)
    {
      "jobGeo" => card.css('[data-test="location"]').text.strip,
      "rating" => card.css('[data-test="rating"]').text.strip
    }
  end

  def job_url(card)
    "https://www.glassdoor.com#{card.css('a[data-test="job-link"]').first['href']}"
  end
end
