# frozen_string_literal: true

module HackerNews
  class FetchJobstories
    attr_reader :jobstory_ids

    def initialize(jobstory_ids:)
      @jobstory_ids = jobstory_ids
    end

    def call(conn: nil)
      conn ||= HackerNews.client

      jobstory_ids.map do |id|
        ap id

        jobstory = Oj.load(get_jobstory(conn:, id:).body, symbolize_names: true)

        next unless jobstory[:type] == 'job'

        attrs = jobstory.slice(:by, :score, :time, :title, :url, :text).merge(data: jobstory)

        HackerNews::V0::Jobstory.create_with(**attrs).find_or_create_by(id:)

        sleep 1
      end

      true
    end

    def get_jobstory(conn:, id:)
      conn.get("/v0/item/#{id}.json")
    end
  end
end

