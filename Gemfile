# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.2'

gem 'active_median'
gem 'ancestry'
gem 'awesome_print'
gem 'babosa'
gem 'bcrypt', '~> 3.1.7'
gem 'bcrypt_pbkdf'
gem 'byebug'
gem 'deepsort'
gem 'druuid'
gem 'ed25519'
gem 'faraday'
gem 'faraday-encoding'
gem 'faraday-http-cache'
gem 'faraday_middleware'
gem 'friendly_id'
gem 'fugit'
gem 'groupdate'
gem 'hightop'
gem 'hiredis'
gem 'jsonb_accessor'
gem 'lograge'
gem 'lograge-sql'
gem 'loofah'
gem 'multi_xml'
gem 'nokogiri'
gem 'nori'
gem 'pg', '~> 1.1'
gem 'pg_query', '>= 0.9.0'
gem 'pg_search'
gem 'pghero'
gem 'pry-byebug'
gem 'pry-rails'
gem 'puma', '~> 5.0', require: false
gem 'rails', '~> 6.1.3', '>= 6.1.3.2'
gem 'rails-html-sanitizer'
gem 'redis', require: %w[redis redis/connection/hiredis]
gem 'rollups' # https://github.com/ankane/rollup
gem 'rubypants', require: false
gem 'sanitize', require: false
gem 'scenic'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'slack-notifier'
gem 'sorted_set'
gem 'stopwords-filter', require: 'stopwords'
gem 'twitter-text', require: false
gem 'typhoeus'
gem 'whenever', require: false

group :development, :test do
  gem 'faker'
  gem 'fuubar', require: false
  gem 'rspec-rails'
  gem 'webmock'
end

group :development do
  gem 'annotate'
  gem 'brakeman'
  gem 'capistrano', '~> 3.10', require: false
  gem 'capistrano-asdf', require: false
  gem 'capistrano-rails', '~> 1.6', require: false
  gem 'guard-rspec', require: false
  gem 'listen', '~> 3.3', require: false
  gem 'lol_dba', require: false
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-require_tools', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rubycw', require: false
  gem 'rubocop-thread_safety', require: false
end

group :development, :test do
  gem 'bullet'
end

group :test do
  gem 'vcr'
end

# gem 'blingfire' # https://github.com/ankane/blingfire
# gem 'connection_pool'
# gem 'eps' # https://github.com/ankane/eps
# gem 'memo_wise'
# gem 'mitie' # https://github.com/ankane/mitie
# gem 'notable' # https://github.com/ankane/notable
# gem 'rainbow'
# gem 'safely_block' # https://github.com/ankane/safely
# gem 'youtokentome' # https://github.com/ankane/youtokentome
