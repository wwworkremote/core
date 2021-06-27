# frozen_string_literal: true

# require 'pry'
# require 'byebug'
#
# require 'faraday'
# require 'faraday_middleware'
# require 'faraday/encoding'
#
# require 'typhoeus/adapters/faraday'
#
# require_relative '../../support/vcr'
# require_relative '../../../lib/spikes/hackernews'
#
# # ActiveSupport::Notifications.subscribe('request.faraday') do |_name, starts, ends, _, env|
# #   url = env[:url]
# #   http_method = env[:method].to_s.upcase
# #   duration = ends - starts
# #   warn format('[%s] %s %s (%.3f s)', url.host, http_method, url.request_uri, duration)
# # end
#
# module Spikes
#   RSpec.describe Hackernews do
#     it 'example request', :vcr do
#       faraday = Faraday.new do |f|
#         f.headers[:user_agent] = 'OutlierJobs::HackerNews/1.0'
#
#         f.url_prefix = 'https://hacker-news.firebaseio.com'
#         f.path_prefix = 'v0'
#
#         f.headers[:accept] = 'application/json; charset=utf-8'
#
#         f.response :json, content_type: /\bjson$/
#         f.response :encoding
#         f.response :follow_redirects
#
#         # f.response :logger, nil, { headers: true, bodies: true }
#
#         # f.use :instrumentation
#
#         f.adapter :typhoeus
#       end
#
#       response = faraday.get('jobstories.json')
#
#       ap response
#     end
#   end
# end
