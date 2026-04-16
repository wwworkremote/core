# frozen_string_literal: true

module Remoteok
  class Fetcher
    include ApiGuard

    API_URL = 'https://remoteok.com/api'

    def call(force: false)
      with_api_guard('remoteok', cooldown: 2.hours, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        response = Faraday.get(API_URL)
        return false unless response.success?

        data = Oj.load(response.body)
        # RemoteOK returns an array where the first item is legal/info, jobs follow
        jobs = data.is_a?(Array) ? data.select { |item| item['id'].present? } : []

        jobs.each do |job_data|
          signature = "remoteok-#{job_data['id']}"

          JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
            doc.source_id = source.id
            doc.job_boards_query_id = query.id
            doc.document = job_data.to_json
          end
        end

        Rails.logger.info "RemoteOK: Fetched #{jobs.count} jobs."
        true
      end
    end
  end
end
