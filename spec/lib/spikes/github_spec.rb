# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

require_relative '../../support/vcr'
require_relative '../../../lib/spikes/github'

module Spikes
  RSpec.describe Github do
    it do
      actual = 1
      expected = 1
      expect(actual).to eq(expected)

      conn = Faraday::Connection.new(url: 'https://httpbingo.org/') do |faraday|
        faraday.use VCR::Middleware::Faraday do |cassette|
          cassette.name    'faraday_example'
          cassette.options record: :new_episodes
        end

        faraday.adapter :typhoeus
      end
    end
  end
end
