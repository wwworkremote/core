# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

gem 'rails', '~>6.1'

# gem 'sequel'
# gem 'sequel_pg', require: 'sequel'

gem 'active_median'
gem 'addressable'
gem 'amazing_print'
gem 'babosa'
gem 'brotli'
gem 'composite_primary_keys', '=13.0.0'
gem 'concurrent-ruby'
gem 'debug'
gem 'deepsort'
gem 'domain_name'
gem 'druuid'
gem 'faraday'
gem 'faraday-encoding'
gem 'faraday-http-cache'
gem 'faraday_middleware'
gem 'friendly_id'
gem 'groupdate'
gem 'hightop'
gem 'hiredis'
gem 'iconv'
gem 'jsonb_accessor'
gem 'loofah'
gem 'multi_json'
gem 'multi_xml'
gem 'newrelic_rpm'
gem 'nokogiri'
gem 'nori'
gem 'oj'
gem 'pg', '~>1.2' # https://github.com/jeremyevans/sequel_pg/issues/34
gem 'pg_party'
gem 'pg_query', '>=0.9.0'
gem 'public_suffix'
gem 'rails-html-sanitizer'
gem 'redis', require: %w[redis redis/connection/hiredis]
gem 'rubypants'
gem 'sanitize'
gem 'scenic'
gem 'sd_notify'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'sidekiq', require: false
gem 'sidekiq-failures'
gem 'sidekiq-throttled'
gem 'sorted_set'
gem 'stopwords-filter', require: 'stopwords'
gem 'whenever', require: false
gem 'whois'
gem 'whois-parser'

group :development do
  gem 'bcrypt_pbkdf', require: false
  gem 'capistrano'
  gem 'capistrano-asdf'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'ed25519', require: false
  gem 'listen', '~>3.3', require: false
  gem 'retest'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-require_tools', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rubycw', require: false
  gem 'rubocop-sequel', require: false
  gem 'rubocop-thread_safety', require: false
  gem 'solargraph'
  gem 'sshkit', require: false
  gem 'sshkit-sudo', require: false
  gem 'yard'
end

group :development, :test do
  gem 'byebug'
  gem 'faker'
  gem 'fuubar', require: false
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', require: false
  gem 'webmock', require: false
end

group :test do
  gem 'vcr', require: false
end

gem 'pghero'

gem 'rails_event_store'

