# frozen_string_literal: true

class Scraper::Enricher
  def self.call(job_posting)
    return if job_posting.target_url.blank?

    enrich_posting(job_posting)
  end

  def self.call_for_link(discovery_link)
    return if JobPosting.exists?(target_url: discovery_link.url)

    board_specific_extract(discovery_link)
  end

  # API-first extraction where a board has one (cord); fall back to standard
  # browsing-based enrichment for everything else.
  def self.board_specific_extract(discovery_link)
    case discovery_link.board_name.downcase
    when "cord" then extract_cord_job(discovery_link)
    else extract_generic_job(discovery_link)
    end
  end

  def self.extract_cord_job(discovery_link)
    listing_id = cord_listing_id(discovery_link.url)
    return extract_generic_job(discovery_link) unless listing_id

    data = fetch_cord_data(listing_id)
    return extract_generic_job(discovery_link) unless data

    create_cord_job_posting(discovery_link, listing_id, data)
  end

  def self.cord_listing_id(url)
    url.match(%r{jobs/(\d+)})&.[](1)
  end

  def self.fetch_cord_data(listing_id)
    response = Faraday.get("https://cord.com/api/v2/public/position/#{listing_id}")
    return nil unless response.success?

    JSON.parse(response.body)["data"]
  end

  def self.create_cord_job_posting(discovery_link, listing_id, data)
    JobPosting.create!(cord_attrs(discovery_link, listing_id, data))
    discovery_link.update!(status: "processed")
  end

  def self.cord_attrs(discovery_link, listing_id, data)
    cord_content_attrs(discovery_link, data).merge(enrichment_envelope("cord-#{listing_id}"))
  end

  def self.cord_content_attrs(discovery_link, data)
    { title: data["position"], company: data["companyName"], target_url: discovery_link.url,
      body: data["jobDescription"], location: data["locationCity"] }
  end

  def self.enrichment_envelope(signature_seed)
    { status: "none", crawl_status: "enriched", enriched_at: Time.current,
      signature: Digest::SHA256.hexdigest(signature_seed) }
  end

  def self.extract_generic_job(discovery_link)
    data = extract_canonical_data(discovery_link.url, discovery_link.board_name)
    return unless data

    create_generic_job_posting(discovery_link, data)
  end

  def self.extract_canonical_data(url, board_name)
    fetch_result = JobFetchers::PageFetch.new(url).call
    return nil unless fetch_result

    JobFetchers::CanonicalJobExtractor.new(fetch_result[:content], fetch_result[:final_url], board_name).call
  end

  def self.create_generic_job_posting(discovery_link, data)
    JobPosting.create!(generic_attrs(discovery_link, data))
    discovery_link.update!(status: "processed")
  end

  def self.generic_attrs(discovery_link, data)
    generic_content_attrs(discovery_link, data)
      .merge(enrichment_envelope("#{discovery_link.board_name}-#{discovery_link.url}"))
  end

  def self.generic_content_attrs(discovery_link, data)
    { title: data[:title], company: data[:company], target_url: discovery_link.url,
      body: data[:body], location: data[:location] }
  end

  def self.enrich_posting(job_posting)
    data = extract_canonical_data(job_posting.target_url, job_posting.source&.name || "manual")
    return unless data

    job_posting.update!(body: data[:body] || job_posting.body, enriched_at: Time.current, crawl_status: "enriched")
  end
end
