# frozen_string_literal: true

# jobs.rubyonrails.org (the official Rails job board) publishes an RSS feed
# rather than a JSON API -- lower-friction than scraping the HTML listing
# (no auth, structured, no client-side rendering to fight). Nokogiri parses
# it directly; no dedicated RSS gem needed, it's already a Rails dependency.
class RailsJobBoard::Fetcher
  include ApiGuard

  FEED_URL = "https://jobs.rubyonrails.org/jobs.rss"
  FIELDS = { "title" => "title", "link" => "link", "description" => "description", "pub_date" => "pubDate" }.freeze

  def call(force: false)
    with_api_guard("rubyonrails", cooldown: 4.hours, force:) do |source|
      fetch_and_store(source)
    end
  end

  private

  def fetch_and_store(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    jobs = fetch_jobs
    store_documents(jobs, source, query) if jobs
  end

  def fetch_jobs
    response = JobBoards::Client.new("rubyonrails").get(FEED_URL)
    return nil unless response && response.status == 200

    jobs = parse_feed(response.body)
    Rails.logger.info "RailsJobBoard: Fetched #{jobs.count} jobs."
    jobs
  end

  def parse_feed(body)
    Nokogiri::XML(body).css("item").filter_map { |item| item_to_hash(item) }
  end

  def item_to_hash(item)
    guid = text_of(item, "guid")
    return nil if guid.blank?

    FIELDS.transform_values { |sel| text_of(item, sel) }.merge("guid" => guid)
  end

  def text_of(item, selector)
    item.at_css(selector)&.text
  end

  def store_documents(jobs, source, query)
    jobs.each { |job_data| store_document(job_data, source, query) }
  end

  # One cohesive find_or_create_by! call -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def store_document(job_data, source, query)
    signature = "rubyonrails-#{job_data['guid']}"

    JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
      doc.source_id = source.id
      doc.job_boards_query_id = query.id
      doc.document = job_data.to_json
    end
  end
  # rubocop:enable Metrics/MethodLength
end
