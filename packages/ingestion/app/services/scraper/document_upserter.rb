# frozen_string_literal: true

# Persists every scraped job listing as JobBoards::Document on each sighting,
# overwriting any prior signature match. Shared by the Playwright ApiClients
# that treat a listing as mutable/re-scraped every run (Dice, Glassdoor) --
# LinkedIn and Indeed instead skip anything already on file and are routed
# through Scraper::DocumentImporter, since that's a different persistence
# policy, not just duplicated code.
class Scraper::DocumentUpserter
  def self.call(...)
    new(...).call
  end

  def initialize(provider, source, query, results)
    @provider = provider
    @source = source
    @query = query
    @results = results
  end

  def call
    @results.each { |job_data| upsert!(job_data) }
    @results.size
  end

  private

  def upsert!(job_data)
    doc = JobBoards::Document.find_or_initialize_by(signature: signature(job_data))
    doc.assign_attributes(attributes_for(job_data))
    doc.save!
  end

  def attributes_for(job_data)
    { source_id: @source.id, job_boards_query_id: @query.id }
      .merge(document: job_data.to_json, aasm_state: "pending")
  end

  def signature(job_data)
    Digest::SHA256.hexdigest("#{@provider}-#{job_data['external_id']}")
  end
end
