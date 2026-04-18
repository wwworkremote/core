# frozen_string_literal: true

module Arbeitnow
  class Fetcher
    include ApiGuard

    API_URL = 'https://www.arbeitnow.com/api/job-board-api'

    def call(force: false)
      with_api_guard('arbeitnow', cooldown: 2.hours, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        client = JobBoards::Client.new('arbeitnow')
        response = client.get(API_URL)
        return false if response.nil? || response.status != 200

        data = Oj.load(response.body)
        jobs = data['data'] || []

        jobs.each do |job_data|
          signature = "arbeitnow-#{job_data['slug']}"

          JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
            doc.source_id = source.id
            doc.job_boards_query_id = query.id
            doc.document = job_data.to_json
          end
        end

        Rails.logger.info "Arbeitnow: Fetched #{jobs.count} jobs."
        true
      end
    end
  end
end
