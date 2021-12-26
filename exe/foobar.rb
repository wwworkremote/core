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
    MultiJson.load(str)
  end

  def self.dump_json(val)
    MultiJson.dump(val)
  end
end

SOURCE_ID = 'e88c9334-f35f-4911-bd21-4729bb7b4a31'

query = PGDATABASE[:sources].where(id: SOURCE_ID)

records = query.stream.each_with_object([]) { |record, a| a << record }

ap query
ap records

__END__

RawResponseSchema = Dry::Schema.Params do
  required(:raw_response_id).filled(:integer)
  required(:created_at).filled(:string)
  required(:headers).filled(:string)
  required(:body).filled(:string)
  required(:code).filled(:integer)
  required(:uuid).filled(Types::Uuid)

  optional(:error).maybe(:string)

  # before(:value_coercer) do |result|
  #   result.to_h.compact
  # end
end

RAW_RESPONSES.map { |params| RawResponseSchema.call(params) }

params = RAW_RESPONSES.first
ap params
puts

ap RawResponseSchema.call(params)

__END__

COOKIE_ID = '0e44769d-48c4-4a85-a844-8558a2e48c54'

class Command
  include Dry::Monads::Result::Mixin
  include Dry::Monads::Do.for(:call)

  def call(params)
    ap([self.class.name, __method__, params])

    values = yield(validate(params))
    values = yield(transform(values))

    log(values)

    Success(values)
  end

  def validate(params)
    ap([self.class.name, __method__, params])

    RawResponseSchema.call(params).to_monad
  end

  def transform(values)
    ap([self.class.name, __method__, values])
    values
  end

  def log(values)
    ap([self.class.name, __method__, values])
  end
end

output = Command.new.call(params)
puts
puts '-' * 100
puts
ap output, multiline: false

# ap Functions[:load_json].call(body)

__END__
import Dry::Transformer::ArrayTransformations
import Dry::Transformer::ClassTransformations
import Dry::Transformer::Coercions
import Dry::Transformer::Conditional
import Dry::Transformer::HashTransformations
import Dry::Transformer::ProcTransformations
import Dry::Transformer::Recursion
import :to_string, from: Dry::Transformer::Coercions, as: :stringify

__END__
MONGO = Mongoid.client(:default)

module App
  def self.persist(mongodb_collection, documents)
    mongodb_collection.bulk_write(documents, ordered: false)
  rescue Mongo::Error::BulkWriteError => e
    # Ignore duplicates # e.result['writeErrors'].count
    only_write_errors = e.result['writeErrors'].all? { |error| error['code'] == 11_000 }
    raise unless only_write_errors
  end
end

module Entities
  class SymbolizeStruct < Dry::Struct
    transform_keys(&:to_sym)
  end

  class Cookie < SymbolizeStruct
    attribute :cookie_id, Types::CookieId
    attribute :created_at, 'json.time'
  end

  class ServiceCall < SymbolizeStruct
    attribute :cookie_id, Types::CookieId
    attribute :created_at, 'json.time'
    attribute :raw_request_id, 'strict.integer'
    attribute :raw_response_id, 'strict.integer'
    attribute :service_call_id, 'strict.integer'
    attribute :service_call_source_id, 'strict.integer'
  end

  class RawRequest < SymbolizeStruct
    attribute :body, 'strict.string'
    attribute :created_at, 'json.time'
    attribute :headers, 'strict.string'
    attribute :raw_request_id, 'strict.integer'
    attribute :url_id, 'strict.integer'
    attribute :url_params, 'strict.string'
    attribute :uuid, Types::Uuid
  end

  class RawResponse < SymbolizeStruct
    attribute :body, 'strict.string'
    attribute :code, 'strict.integer'
    attribute :created_at, 'json.time'
    attribute :error, Dry::Types['strict.string'].optional
    attribute :headers, 'strict.string'
    attribute :raw_response_id, 'strict.integer'
    attribute :uuid, Types::Uuid
  end
end
# ---

mongodb_collection = MONGO[:cookies]
mongodb_collection.create! rescue nil

query = PGDATABASE[:cookies].where(cookie_id: COOKIE_ID)

records = query.stream.each_with_object([]) { |record, a| a << record }

entities = records.map { |record| Entities::Cookie.new(record) }
documents = entities.map { |entity| { insert_one: entity.as_json } }

App.persist(mongodb_collection, documents)

puts
ap [:cookies, { count: ::Cookie.count, record: records.last, entity: entities.last, document: documents.last }]

# ---

mongodb_collection = MONGO[:service_calls]
mongodb_collection.create! rescue nil

MONGO.database.command(collMod: 'service_calls', validator: { :$or => [{ cookie_id: { :$type => 'string' } }, { raw_request_id: { :$type => 'number' } }, { raw_response_id: { :$type => 'number' } }, { service_call_id: { :$type => 'number' } }, { service_call_source_id: { :$type => 'number' } }] })
mongodb_collection.indexes.create_many([{ key: { cookie_id: 1 } }, { key: { created_at: -1 } }, { key: { raw_request_id: -1 } }, { key: { raw_response_id: -1 } }, { key: { service_call_id: -1 }, unique: true }, { key: { service_call_source_id: -1 } }])

query = PGDATABASE[:service_calls].where(cookie_id: COOKIE_ID)

records = query.stream.each_with_object([]) { |record, a| a << record }

raw_request_ids = Concurrent::Set.new(records.pluck(:raw_request_id))
raw_response_ids = Concurrent::Set.new(records.pluck(:raw_response_id))

entities = records.map { |record| Entities::ServiceCall.new(record) }

#

documents = entities.map { |entity| { insert_one: entity.as_json } }

App.persist(mongodb_collection, documents)

puts
ap [:service_calls, { count: ::ServiceCall.count, record: records.last, entity: entities.last, document: documents.last }]

# ---

mongodb_collection = MONGO[:raw_requests]
mongodb_collection.create! rescue nil

query = PGDATABASE[:raw_requests].where(raw_request_id: raw_request_ids.to_a)
records = query.stream.each_with_object([]) { |record, a| a << record }
entities = records.map { |record| Entities::RawRequest.new(record) }
documents = entities.map { |entity| { insert_one: entity.as_json } }

record = records.first
entity = entities.first

puts
ap [:raw_requests, { count: ::RawRequest.count, record: records.last, entity: entities.last, document: documents.last }]

# ---

mongodb_collection = MONGO[:raw_responses]

query = PGDATABASE[:raw_responses].where(raw_response_id: raw_response_ids.to_a)
records = query.stream.each_with_object([]) { |record, a| a << record }
entities = records.map { |record| Entities::RawResponse.new(record) }
documents = entities.map { |entity| { insert_one: entity.as_json } }

App.persist(mongodb_collection, documents)

record = records.first
entity = entities.first

puts
ap [:raw_responses, { count: ::RawResponse.count, record: records.last, entity: entities.last, document: documents.last }]

