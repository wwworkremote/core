# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.1'

gem 'awesome_print'
gem 'bcrypt', '~> 3.1.7'
gem 'faraday'
gem 'faraday-encoding'
gem 'faraday_middleware'
gem 'hiredis'
gem 'multi_xml'
# gem 'nokogiri'
# gem 'nori'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.0'
gem 'rails', '~> 6.1.3', '>= 6.1.3.2'
# gem 'rash_alt', require: 'rash'
gem 'redis', require: %w[redis redis/connection/hiredis]
# gem 'rss'
# gem 'safe_yaml'
gem 'rack-cors'
gem 'sass-rails', '>= 6'
gem 'typhoeus'

group :development, :test do
  gem 'byebug'
  gem 'fuubar', require: false
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails'
end

group :development do
  gem 'capistrano', '~> 3.10', require: false
  gem 'capistrano-asdf', require: false
  gem 'capistrano-rails', '~> 1.6', require: false
  gem 'guard-rspec', require: false
  gem 'listen', '~> 3.3'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-require_tools', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rubycw', require: false
  gem 'rubocop-thread_safety', require: false
  gem 'vcr'
end
