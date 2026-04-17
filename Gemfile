# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '4.0.2'

gem 'rails', github: 'rails/rails', branch: 'main'

# Core / Data Acquisition
gem 'aasm'
gem 'active_median'
gem 'after_commit_everywhere', '~> 1.0'
gem 'ahoy_matey'
gem 'amazing_print'
gem 'annotaterb', '~> 4.10'
gem 'avo'
gem 'bcrypt', '~> 3.1.7'
# gem 'blorgh', path: 'blorgh'
gem 'chartkick'
gem 'dartsass-rails', github: 'rails/dartsass-rails', branch: 'main'
gem 'devise', '~> 4.9'
gem 'druuid'
gem 'faraday'
gem 'faraday-net_http_persistent'
gem 'feedjira', '~> 4.0'
gem 'ferrum'
gem 'geocoder'
gem 'groupdate'
gem 'importmap-rails', github: 'rails/importmap-rails', branch: 'main'
gem 'inline_svg'
gem 'jbuilder'
gem 'jsonb_accessor', '~> 1.0'
gem 'kamal'
gem 'kaminari', '~> 1.2'
gem 'kredis'
gem 'meta-tags'
gem 'neighbor'
gem 'oj'
gem 'opentelemetry-api'
gem 'opentelemetry-exporter-otlp'
gem 'opentelemetry-instrumentation-all'
gem 'opentelemetry-sdk'
gem 'pagy'
gem 'paper_trail'
gem 'pg', '~> 1.1'
gem 'pg_query', '>= 2'
gem 'pg_search', '~> 2.3'
gem 'pgvector'
gem 'playwright-ruby-client'
gem 'propshaft', github: 'rails/propshaft', branch: 'main'
gem 'puma', '>= 6.0'
gem 'rack-cors'
gem 'ransack'
gem 'ruby_llm'
gem 'sidekiq', '>= 8.0'
gem 'sidekiq-cron'
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'
gem 'stimulus-rails', github: 'hotwired/stimulus-rails', branch: 'main'
gem 'tailwindcss-rails', '~> 4.0'
gem 'thruster'
gem 'turbo_power'
gem 'turbo-rails', github: 'hotwired/turbo-rails', branch: 'main'
gem 'tzinfo-data', platforms: %i[windows jruby]

# Development & Testing
group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capybara'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'overcommit'
  gem 'pghero'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-md', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'rubocop-rubycw', require: false
  gem 'rubocop-thread_safety', require: false
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'rack-mini-profiler'
end
