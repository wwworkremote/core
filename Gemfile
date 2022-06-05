# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

gem 'pg', '~> 1.1'
gem 'rails', '~> 7.0.3'

gem 'puma', '~> 5.0'

gem 'hiredis'
gem 'kredis'
gem 'redis', require: %w[redis redis/connection/hiredis]

gem 'whenever', require: false

gem 'druuid'

group :development do
  gem 'capistrano', require: false
  gem 'capistrano-asdf', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails', require: false

  gem 'bcrypt_pbkdf', require: false
  gem 'ed25519', require: false
  gem 'sshkit', require: false
  gem 'sshkit-sudo', require: false

  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-require_tools', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rubycw', require: false
  gem 'rubocop-thread_safety', require: false

  gem 'listen', '~>3.3', require: false
end

group :development, :test do
  gem 'debug'
end

# group :test do
#   gem 'vcr', require: false
# end

# gem 'active_median'
# gem 'addressable'
# gem 'amazing_print'
# gem 'babosa'
# gem 'brotli'
# gem 'composite_primary_keys', '=13.0.0'
# gem 'concurrent-ruby'
# gem 'debug'
# gem 'deepsort'
# gem 'domain_name'
# gem 'faker'
# gem 'faraday'
# gem 'faraday-encoding'
# gem 'faraday-http-cache'
# gem 'faraday_middleware'
# gem 'friendly_id'
# gem 'fuubar', require: false
# gem 'groupdate'
# gem 'hightop'
# gem 'iconv'
# gem 'jsonb_accessor'
# gem 'loofah'
# gem 'multi_json'
# gem 'multi_xml'
# gem 'nokogiri'
# gem 'nori'
# gem 'oj'
# gem 'pg', '~>1.2' # https://github.com/jeremyevans/sequel_pg/issues/34
# gem 'pg_party'
# gem 'pg_query', '>=0.9.0'
# gem 'pghero'
# gem 'public_suffix'
# gem 'rails-html-sanitizer'
# gem 'rails_event_store'
# gem 'retest'
# gem 'rspec-rails', require: false
# gem 'rubocop-sequel', require: false
# gem 'rubypants'
# gem 'sanitize'
# gem 'scenic'
# gem 'sd_notify'
# gem 'sequel'
# gem 'sequel_pg', require: 'sequel'
# gem 'sidekiq', require: false
# gem 'sidekiq-failures'
# gem 'sidekiq-throttled'
# gem 'solargraph'
# gem 'sorted_set'
# gem 'stopwords-filter', require: 'stopwords'
# gem 'webmock', require: false
# gem 'whois'
# gem 'whois-parser'
# gem 'yard'
