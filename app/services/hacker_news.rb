# frozen_string_literal: true

module HackerNews
  module_function

  def client
    url = 'https://hacker-news.firebaseio.com'

    Faraday.new(
      url:,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def min_jobstory_id
    HackerNews::V0::Jobstory.minimum(:id)
  end
end
