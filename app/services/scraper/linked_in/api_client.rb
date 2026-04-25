# frozen_string_literal: true

require 'nokogiri'

class Scraper::LinkedIn::ApiClient
  # LinkedIn guest search URL
  BASE_URL = 'https://www.linkedin.com/jobs/search'

  def self.search(keywords, location: 'Remote')
    new.search(keywords, location)
  end

  def call
    # Default search if called without arguments via DataAcquisitionManager
    search('Staff Ruby Engineer', 'Remote')
  end

  def search(keywords, location)
    source = JobBoards::Source.find_by(slug: 'linkedin')
    query = JobBoards::Query.find_by(source_id: source&.id)

    params = {
      keywords: keywords,
      location: location,
      f_WT: 2 # Remote filter
    }

    url = "#{BASE_URL}?#{params.to_query}"
    Rails.logger.info "[LinkedIn::ApiClient] Fetching: #{url}"

    fetch_result = JobFetchers::PageFetch.new(url).call
    return { success: false, error: 'Fetch failed' } unless fetch_result

    data = parse_results(fetch_result[:content])

    processed_count = 0
    data['results'].each do |job_data|
      signature = Digest::SHA256.hexdigest("linkedin-#{job_data['external_id']}")
      doc = JobBoards::Document.find_or_initialize_by(signature: signature)
      next unless doc.new_record?
      doc.source_id = source&.id
      doc.job_boards_query_id = query&.id
      doc.document = job_data.to_json
      doc.save!
      processed_count += 1
    end

    { success: true, count: processed_count }
  end

  private

  def parse_results(html)
    doc = Nokogiri::HTML(html)
    results = []

    # LinkedIn guest search result cards
    doc.css('.base-card').each do |card|
      title_link = card.css('a.base-card__full-link').first
      next unless title_link

      href = title_link['href']
      job_id = href.match(%r{/view/(\w+-\w+|(\d+))})&.[](0)&.split('-')&.last || href.match(%r{view/(\d+)})&.[](1)

      # If we can't get a clean numeric ID, use a hash of the href
      job_id ||= Digest::MD5.hexdigest(href)[0..10]

      results << {
        'jobTitle' => card.css('.base-search-card__title').text.strip,
        'companyName' => card.css('.base-search-card__subtitle').text.strip,
        'jobGeo' => card.css('.job-search-card__location').text.strip,
        'url' => href.split('?').first, # Clean URL
        'external_id' => job_id,
        'found_by_terms' => nil
      }
    end

    { 'results' => results }
  end
end
