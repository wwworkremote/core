# frozen_string_literal: true

require 'digest'

module Adzuna
  class Fetcher
    include ApiGuard
    BASE_URL = 'https://api.adzuna.com/v1/api/jobs/us/search/1'

    def call
      app_id = ENV.fetch('ADZUNA_APPLICATION_ID', nil)
      app_key = ENV.fetch('ADZUNA_APPLICATION_KEY', nil)

      return puts 'Adzuna API credentials missing. Skipping.' unless app_id && app_key

      with_api_guard('adzuna', cooldown: 4.hours) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        conn = Faraday.new(url: BASE_URL) do |f|
        f.params['app_id'] = app_id
        f.params['app_key'] = app_key
        f.params['what'] = 'remote'
        f.params['content-type'] = 'application/json'
      end

      response = conn.get
      data = JSON.parse(response.body)

      unless data['results']
        puts "Adzuna API Error: #{response.body}"
        return
      end

      data['results'].each do |job|
        signature = Digest::SHA256.hexdigest("adzuna-#{job['id']}")
        
        JobBoards::Document.find_or_create_by!(signature:) do |doc|
          doc.source_id = source.id
          doc.job_boards_query_id = query.id
          doc.document = job.to_json
        end
      end
    end
  end
end
