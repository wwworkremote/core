# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.2'

gem 'rails', '~> 6.1.4', '>= 6.1.4'

gem 'active_median'
gem 'addressable'
gem 'amazing_print'
gem 'babosa'
gem 'bcrypt_pbkdf', require: false
gem 'brotli'
gem 'deepsort'
gem 'domain_name'
gem 'druuid'
gem 'ed25519', require: false
gem 'eps' # https://github.com/ankane/eps
gem 'faraday'
gem 'faraday-encoding'
gem 'faraday-http-cache'
gem 'faraday_middleware'
gem 'friendly_id'
gem 'groupdate'
gem 'hightop'
gem 'hiredis'
gem 'jsonb_accessor'
gem 'loofah'
gem 'multi_xml'
gem 'nokogiri'
gem 'nori'
gem 'ougai'
gem 'pg', '~> 1.1'
gem 'pgdexter'
gem 'pghero'
gem 'pg_query', '>= 0.9.0'
gem 'pg_search'
gem 'pgslice'
gem 'pgsync'
gem 'public_suffix'
gem 'puma', '~> 5.5.2'
gem 'puma_worker_killer'
gem 'rails-html-sanitizer'
gem 'redis', require: %w[redis redis/connection/hiredis]
gem 'rubypants', require: false
gem 'sanitize', require: false
gem 'scenic'
gem 'sd_notify'
gem 'sidekiq'
gem 'sorted_set'
gem 'stopwords-filter', require: 'stopwords'
gem 'twitter_cldr', '~> 6.7'
gem 'twitter-text'
gem 'typhoeus'
gem 'whenever', require: false
gem 'whois'
gem 'whois-parser'

group :production do
  gem 'newrelic_rpm'
  gem 'sentry-rails'
  gem 'sentry-ruby'
end

group :development do
  gem 'annotate'
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false

  gem 'sshkit', require: false
  gem 'sshkit-sudo', require: false

  gem 'capistrano', '~> 3.10', require: false
  gem 'capistrano-asdf', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails', '~> 1.6', require: false

  gem 'erb_lint', require: false
  gem 'listen', '~> 3.3', require: false
  gem 'rails-erd'
  gem 'retest'

  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-require_tools', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rubycw', require: false
  gem 'rubocop-thread_safety', require: false

  gem 'webrick', require: false
end

group :development, :test do
  gem 'byebug'
  gem 'faker', require: false
  gem 'fuubar', require: false
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', require: false
  gem 'webmock', require: false
end

group :test do
  gem 'vcr', require: false
end

# gem 'ancestry'
# gem 'blingfire' # https://github.com/ankane/blingfire
# gem 'cld'
# gem 'connection_pool'
# gem 'fugit'
# gem 'hashie'
# gem 'lol_dba', require: false
# gem 'memo_wise'
# gem 'mitie' # https://github.com/ankane/mitie
# gem 'notable' # https://github.com/ankane/notable
# gem 'rainbow'
# gem 'rash_alt'
# gem 'rollups' # https://github.com/ankane/rollup
# gem 'safe_yaml'
# gem 'safely_block' # https://github.com/ankane/safely
# gem 'slack-notifier'
# gem 'youtokentome' # https://github.com/ankane/youtokentome

# gem 'sidekiq-throttled'
