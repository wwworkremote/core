# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.2'

gem 'rails', '~> 7.0.3', '>= 7.0.3.1'

gem 'aasm'
gem 'after_commit_everywhere', '~> 1.0'
gem 'ahoy_matey'
gem 'amazing_print'
gem 'annotate', '~> 3.2'
gem 'bcrypt', '~> 3.1.7'
gem 'blorgh', path: 'blorgh'
gem 'byebug'
gem 'devise', '~> 4.9'
gem 'druuid'
gem 'faraday', require: false
gem 'faraday-net_http_persistent', require: false
gem 'faraday-retry', require: false
gem 'jbuilder'
gem 'kredis'
gem 'paper_trail'
gem 'pg', '~> 1.1'
gem 'pghero'
gem 'pg_query', '>= 2'
gem 'pry-rails'
gem 'puma', '~> 5.0'
gem 'rack-cors'
gem 'rails_event_store', '~> 2.5.1'
gem 'sidekiq', '~> 6.0', '<7.0'
gem 'sorted_set'
gem 'sprockets-rails'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'whenever', require: false

group :development, :test do
  gem 'debug'
end

group :development do
  gem 'capistrano', require: false
  gem 'capistrano-asdf', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-ssh-doctor', require: false, github: 'capistrano-plugins/capistrano-ssh-doctor'

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
end

gem 'rails_admin', '~> 3.1'
gem 'sassc-rails'
