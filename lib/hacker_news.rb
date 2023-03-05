# frozen_string_literal: true

require 'amazing_print'
require 'faraday'
require 'oj'

module HackerNews
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

    jobstory_ids = Oj.load(pull_jobstories(conn).body)

    jobstory_ids.map do |id|
      jobstory = Oj.load(pull_jobstory(conn, id:).body)

      ap jobstory

      sleep 1
    end
  end
end
