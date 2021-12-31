#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dry/transformer/all'
require 'dry/monads/all'

Dry::Schema.load_extensions(:monads)
Dry::Types.load_extensions(:maybe)
Dry::Validation.load_extensions(:monads)

module Types
  include Dry.Types()
end

module Functions
  extend Dry::Transformer::Registry

  def self.load_json(str)
    MultiJson.load(str, symbolize_keys: true)
  end

  def self.dump_json(val)
    MultiJson.dump(val)
  end
end

SOURCE_ID = 'e88c9334-f35f-4911-bd21-4729bb7b4a31'

query = PGDATABASE[:sources].where(id: SOURCE_ID)

records = query.stream.each_with_object([]) { |record, a| a << record }

payload = Functions.load_json(records.first[:payload]).each { |_, v| v.compact_blank! if v.is_a?(Enumerable) }.compact_blank.deep_symbolize_keys
ap payload

binding.pry
puts
