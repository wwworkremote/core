# frozen_string_literal: true

require 'vcr'

VCR.config do |c|
  c.cassette_library_dir = 'cassettes'
  c.stub_with :faraday
end
