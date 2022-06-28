# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'

require 'json'
require 'set'
require 'base64'

require 'druuid'

INSTANCE_NAME = ENV.fetch('INSTANCE_NAME')

INSTANCES = {
  'node01' => 'node01:3001',
  'node02' => 'node02:3002',
  'node03' => 'node03:3003',
  'node04' => 'node04:3004',
  'node05' => 'node05:3005',
  'zalewhol' => 'zalewhol.local:3000'
}.freeze

keys = Set.new

class Foo
  attr_reader :keys

  def initialize
    @keys = Set.new
  end

  def sig
    @sig = Digest::SHA256.hexdigest(keys.to_a.to_s.tr(' ', ''))
  end
end

get('/instance') { INSTANCES[INSTANCE_NAME] }

get('/push') {
  key = Druuid.gen
  keys.add(key)

  json(key:, count: keys.count, sig: Base64.encode64(keys.to_s).strip)
}

get('/sig') { json({ sig: Base64.encode64(keys.to_a.hash.to_s).strip }) }

get('/count') { json({ count: keys }) }

get('/keys') { json({ keys: }) }

get '/peers' do
  json(INSTANCES)
end
