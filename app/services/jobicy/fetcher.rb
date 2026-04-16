# frozen_string_literal: true

module Jobicy
  class Fetcher
    include ApiGuard

    API_URL = 'https://jobicy.com/api/v2/remote-jobs'

    def call(force: false)
      with_api_guard('jobicy', cooldown: 4.hours, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        response = Faraday.get(API_URL)
        return false unless response.success?

        data = Oj.load(response.body)
        jobs = data['jobs'] || []

        jobs.each do |job_data|
          signature = "jobicy-#{job_data['id']}"

          JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
            doc.source_id = source.id
            doc.job_boards_query_id = query.id
            doc.document = job_data.to_json
          end
        end

        Rails.logger.info "Jobicy: Fetched #{jobs.count} jobs."
        true
      end
    end
  end
end
