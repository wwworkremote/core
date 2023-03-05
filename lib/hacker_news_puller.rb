# frozen_string_literal: true

require 'amazing_print'
require 'faraday'
require 'oj'

module HackerNewsPuller
  module_function

  def pull_jobstories(conn)
    conn.get('/v0/jobstories.json')
  end

  def pull_jobstory(conn, id:)
    conn.get("/v0/item/#{id}.json")
  end

  def pull
    url = 'https://hacker-news.firebaseio.com'

    conn = Faraday.new(url:, headers: { 'Content-Type' => 'application/json' })

    jobstory_ids = Oj.load(pull_jobstories(conn).body, symbolize_names: true)

    jobstory_ids.map do |id|
      jobstory = Oj.load(pull_jobstory(conn, id:).body, symbolize_names: true)

      attrs = jobstory.slice(:by, :score, :time, :title, :url).merge(data: jobstory)

      HackerNews::V0::Jobstory.create_with(**attrs).find_or_create_by(id:)

      sleep 1
    end
  end
end
