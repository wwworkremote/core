# frozen_string_literal: true

require "digest"

class Remotive::Fetcher
  include ApiGuard

  API_URL = "https://remotive.com/api/remote-jobs"

  def call(force: false)
    with_api_guard("remotive", cooldown: 1.hour, force:) do |source|
      fetch_and_store(source)
    end
  end

  private

  def fetch_and_store(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    response = JobBoards::Client.new("remotive").get(API_URL)
    return unless response && response.status == 200

    jobs = JSON.parse(response.body)["jobs"]
    store_documents(jobs, source, query)
  end

  def store_documents(jobs, source, query)
    jobs.each { |job| store_document(job, source, query) }
  end

  # One cohesive find_or_create_by! call -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def store_document(job, source, query)
    signature = Digest::SHA256.hexdigest("remotive-#{job['id']}")

    JobBoards::Document.find_or_create_by!(signature:) do |doc|
      doc.source_id = source.id
      doc.job_boards_query_id = query.id
      doc.document = job.to_json
    end
  end
end
