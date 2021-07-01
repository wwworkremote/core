# frozen_string_literal: true

module StackOverflow
  module_function

  def jobs
    # jobstories = StackOverflow::V0::Jobstories.new.call

    # StackOverflow::V0::Item::Jobs.new(jobstories.data, jobstories.client).call.data
  end

  def client
    # Faraday.new do |f|
    #   f.request :retry, max: 3

    #   f.headers[:user_agent] = 'OutlierJobs::StackOverflow/1.0'

    #   f.url_prefix = 'https://hacker-news.firebaseio.com'
    #   f.path_prefix = 'v0'

    #   f.headers[:accept] = 'application/json; charset=utf-8'

    #   f.response :json, content_type: /\bjson$/
    #   f.response :encoding
    #   f.response :follow_redirects

    #   f.adapter :typhoeus
    # end
  end
end
