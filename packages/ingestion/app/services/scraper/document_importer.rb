# frozen_string_literal: true

# Persists newly-seen job listings as JobBoards::Document, skipping any
# signature already on file. Shared by the Playwright ApiClients that treat
# a posting as immutable once first seen (LinkedIn, Indeed) -- Dice and
# Glassdoor instead upsert on every sighting and are intentionally not
# routed through this collaborator, since that's a different persistence
# policy, not just duplicated code.
class Scraper::DocumentImporter
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
    @results.count { |job_data| import!(job_data) }
  end

  private

  # Mutator, not a predicate -- the boolean return (imported vs. skipped as a
  # duplicate) is incidental, used by #call to count actually-imported rows.
  # rubocop:disable-next Naming/PredicateMethod
  def import!(job_data)
    doc = JobBoards::Document.find_or_initialize_by(signature: signature(job_data))
    return false unless doc.new_record?

    persist!(doc, job_data)
    true
  end

  def persist!(doc, job_data)
    doc.source_id = @source&.id
    doc.job_boards_query_id = @query&.id
    doc.document = job_data.to_json
    doc.save!
  end

  def signature(job_data)
    Digest::SHA256.hexdigest("#{@provider}-#{job_data['external_id']}")
  end
end
