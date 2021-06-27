# frozen_string_literal: true

require 'pry'
require 'byebug'

require 'faraday'
require 'faraday_middleware'

require 'typhoeus/adapters/faraday'

require_relative '../../support/vcr'
require_relative '../../../lib/spikes/hackernews'

module Spikes
  RSpec.describe Hackernews do
    it 'example request', :vcr do
      faraday = Faraday.new do |f|
        f.adapter :typhoeus
        f.headers[:accept] = 'application/json; charset=utf-8'
        # f.headers[:content_type] = 'application/json'
        # f.headers[:user_agent] = 'Hello 1.0'
        f.params['print'] = 'pretty'
        f.path_prefix = 'v0'
        f.request :json
        # f.request :retry
        # f.response :follow_redirects
        f.response :json # , content_type: /\bjson$/
        f.url_prefix = 'https://hacker-news.firebaseio.com'
      end

      response = faraday.get('jobstories.json')

      ap response.to_hash
    end
  end
end
