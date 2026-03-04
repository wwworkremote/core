# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.10'

gem 'rails', '~> 8.0.0'

# Core / Data Acquisition
gem 'aasm'
gem 'after_commit_everywhere', '~> 1.0'
gem 'ahoy_matey'
gem 'amazing_print'
gem 'annotaterb', '~> 4.10'
gem 'bcrypt', '~> 3.1.7'
gem 'blorgh', path: 'blorgh'
gem 'dartsass-rails'
gem 'devise', '~> 4.9'
gem 'druuid'
gem 'faraday'
gem 'faraday-net_http_persistent'
gem 'faraday-retry'
gem 'jbuilder'
gem 'kredis'
gem 'nokogiri', '>= 1.16'
gem 'oj'
gem 'paper_trail'
gem 'pg', '~> 1.5'
gem 'pghero'
gem 'pg_query', '>= 2'
gem 'pg_search', '~> 2.3'
gem 'propshaft'
gem 'puma', '>= 6.0'
gem 'rack-cors'
gem 'rails_admin', '~> 3.1'
gem 'rails_event_store', '~> 2.15'
gem 'solid_cache'
gem 'sprockets-rails'
gem 'thruster', group: :production
# gem 'rollbar', '~> 3.5'
gem 'sidekiq', '>= 7.0'
gem 'sidekiq-cron'
gem 'whenever', require: false

# Dashboard / Visualization
gem 'active_median'
gem 'chartkick'
gem 'feedjira'
gem 'groupdate'
gem 'jsonb_accessor'
gem 'kaminari'

# Assets / UI
# gem 'propshaft'
gem 'importmap-rails'
gem 'stimulus-rails'
gem 'turbo-rails'

group :development, :test do
  gem 'database_cleaner-active_record'
  gem 'debug'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'fasterer', require: false
  gem 'overcommit', require: false
  gem 'rails_best_practices', require: false
  gem 'reek', require: false
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-md', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rubycw', require: false
  gem 'rubocop-thread_safety', require: false
  gem 'ruby-lsp'
end

gem 'newrelic_rpm'
gem 'opentelemetry-exporter-otlp'
gem 'opentelemetry-instrumentation-all'
gem 'opentelemetry-sdk'
