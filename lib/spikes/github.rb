# frozen_string_literal: true

require 'faraday'

require 'faraday_middleware'

module Spikes
  class Github
  end
end

# search_command = GitHubSearchCommand.create_with(
#   parameters: {
#     accept: 'application/json',
#     http_request_method: :get,
#     url: 'https://jobs.github.com/positions.json',
#     querystring: {
#       description: description,
#       full_time: full_time,
#       location: location,
#       page: 1
#     }
#   },
#   data: {
#     pagination: {
#       key: :page,
#       start_at: 1,
#       stop_at: 10
#     }
#   }
# ).find_or_create_by(
#   source_jot_id: source_jot.id,
#   source_jot_type: 'SourceJot',
#   name: name,
#   type: 'GitHubSearchCommand'
# )

# conn = Faraday.new do |f|
#   f.request :json # encode req bodies as JSON
#   f.request :retry # retry transient failures
#   f.response :follow_redirects # follow redirects
#   f.response :json # decode response bodies as JSON
# end
# response = conn.get('http://httpbingo.org/get')
#
# response = Faraday.post('http://httpbingo.org/post') do |req|
#   req.params['limit'] = 100
#   req.headers['Content-Type'] = 'application/json'
#   req.body = { query: 'chunky bacon' }.to_json
# end
