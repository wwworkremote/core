# frozen_string_literal: true

require "digest"

class Adzuna::Fetcher
  include ApiGuard

  BASE_URL = "https://api.adzuna.com/v1/api/jobs/us/search/1"

  def call(force: false)
    return false unless credentials_present?

    with_api_guard("adzuna", cooldown: 4.hours, force:) do |source|
      fetch_and_store(source)
    end
  end

  private

  def credentials_present?
    return true if ENV.fetch("ADZUNA_APPLICATION_ID", nil) && ENV.fetch("ADZUNA_APPLICATION_KEY", nil)

    Rails.logger.error "Adzuna API credentials missing."
    false
  end

  # One cohesive params hash -- splitting it further would obscure it,
  # not simplify it.
  # rubocop:disable Metrics/MethodLength
  def request_params
    {
      app_id: ENV.fetch("ADZUNA_APPLICATION_ID", nil),
      app_key: ENV.fetch("ADZUNA_APPLICATION_KEY", nil),
      what: "remote",
      "content-type": "application/json"
    }
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def fetch_and_store(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    response = JobBoards::Client.new("adzuna").get(BASE_URL, request_params)
    return false if response.nil? || response.status != 200

    results = parse_results(response.body)
    return unless results

    store_documents(results, source, query)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def parse_results(body)
    results = JSON.parse(body)["results"]
    return results if results

    puts "Adzuna API Error: #{body}"
    nil
  end

  def store_documents(jobs, source, query)
    jobs.each { |job| store_document(job, source, query) }
  end

  # One cohesive find_or_create_by! call -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def store_document(job, source, query)
    signature = Digest::SHA256.hexdigest("adzuna-#{job['id']}")

    JobBoards::Document.find_or_create_by!(signature:) do |doc|
      doc.source_id = source.id
      doc.job_boards_query_id = query.id
      doc.document = job.to_json
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
