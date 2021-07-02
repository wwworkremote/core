# frozen_string_literal: true

module StackOverflow
  module_function

  def jobs(_params = {})
    feed = StackOverflow::Jobs::Feed.new(nil, nil).call

    feed.data.dig('rss', 'channel', 'item')
  end

  def client
    Faraday.new do |f|
      f.request :retry, max: 3

      f.headers[:user_agent] = 'OutlierJobs::StackOverflow/1.0'

      f.url_prefix = 'https://stackoverflow.com/'
      f.path_prefix = 'jobs'

      f.headers[:accept] = 'application/rss+xml; charset=utf-8'

      f.response :xml, content_type: /\bxml$/
      f.response :encoding
      f.response :follow_redirects

      f.adapter :typhoeus
    end
  end
end
