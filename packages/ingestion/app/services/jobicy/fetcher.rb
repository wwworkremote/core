# frozen_string_literal: true

class Jobicy::Fetcher
  include ApiGuard

  API_URL = "https://jobicy.com/api/v2/remote-jobs"

  def call(force: false)
    with_api_guard("jobicy", cooldown: 4.hours, force:) do |source|
      fetch_and_store(source)
    end
  end

  private

  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def fetch_and_store(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    response = JobBoards::Client.new("jobicy").get(API_URL)
    return unless response && response.status == 200

    jobs = Oj.load(response.body)["jobs"] || []
    store_documents(jobs, source, query)
    Rails.logger.info "Jobicy: Fetched #{jobs.count} jobs."
  end

  def store_documents(jobs, source, query)
    jobs.each { |job_data| store_document(job_data, source, query) }
  end

  # One cohesive find_or_create_by! call -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def store_document(job_data, source, query)
    signature = "jobicy-#{job_data['id']}"

    JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
      doc.source_id = source.id
      doc.job_boards_query_id = query.id
      doc.document = job_data.to_json
    end
  end
end
