# frozen_string_literal: true

class Lever::Fetcher
  include ApiGuard

  BASE_URL = "https://api.lever.co/v0/postings"

  def call(force: false)
    with_api_guard("lever", cooldown: 4.hours, force:) do |source|
      query = JobBoards::Query.find_or_create_by!(source_id: source.id)

      sites = query.data["sites"] || %w[gitlab netflix palantir]
      terms = query.data["terms"] || [""]

      sites.each do |site|
        terms.each do |term|
          # Enqueue granular jobs instead of looping here
          JobBoards::GranularFetchJob.perform_later(self.class.name, site, term, source.id, query.id)
        end
      end
      true
    end
  rescue StandardError => e
    Rails.logger.error "Lever Fetcher Error: #{e.message}"
    false
  end

  def fetch_granular(site, term, source_id, query_id)
    client = JobBoards::Client.new("lever")
    limit = 100
    skip = 0

    loop do
      url = "#{BASE_URL}/#{site}?mode=json&limit=#{limit}&skip=#{skip}"
      response = client.get(url)
      break if response.nil? || response.status != 200

      jobs = Oj.load(response.body)
      break if jobs.empty?

      process_jobs(jobs, site, term, source_id, query_id)

      Rails.logger.info "Lever: Fetched jobs for #{site} with term '#{term}' (skip: #{skip})."
      break if jobs.count < limit
      skip += limit
    end
  end

  private

  def process_jobs(jobs, site, term, source_id, query_id)
    jobs.each do |job_data|
      next if term.present? && job_data["text"].downcase.exclude?(term.downcase)

      signature = "lever-#{site}-#{job_data['id']}"
      doc = JobBoards::Document.find_or_initialize_by(signature: signature)
      doc.source_id = source_id
      doc.job_boards_query_id = query_id

      current_payload = doc.document.present? ? JSON.parse(doc.document) : job_data
      current_payload["found_by_terms"] ||= []
      current_payload["found_by_terms"] << term if term.present? && current_payload["found_by_terms"].exclude?(term)
      current_payload["site_slug"] = site

      doc.document = current_payload.to_json
      doc.save!
    end
  end
end
