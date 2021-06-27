# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

require_relative '../../support/vcr'
require_relative '../../../lib/spikes/github'

module Spikes
  RSpec.describe Github do
    it 'example request', :vcr  do
      actual = 1
      expected = 1
      expect(actual).to eq(expected)

      conn = Faraday::Connection.new(url: 'https://httpbingo.org/') do |faraday|
        faraday.adapter :typhoeus
      end

      ap conn.get
    end
  end
end
