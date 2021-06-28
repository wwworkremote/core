# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = false
  c.cassette_library_dir = 'spec/cassettes'
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :new_episodes }
  c.default_cassette_options = { serialize_with: :json }
  c.hook_into :faraday
  c.ignore_localhost = false
end
