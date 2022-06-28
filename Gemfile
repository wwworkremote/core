# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

gem 'base64', require: false
gem 'druuid', require: false
gem 'json', require: false
gem 'moneta', require: false
gem 'puma', require: false
gem 'rack', require: false
gem 'rack-cache', require: false
gem 'rack-unreloader', require: false
gem 'sinatra', require: false
gem 'sinatra-contrib', require: false
gem 'webrick', require: false
gem 'whenever', require: false

group :development do
  gem 'capistrano', require: false
  gem 'capistrano-asdf', require: false
  gem 'capistrano-bundler', require: false

  gem 'bcrypt_pbkdf', require: false
  gem 'ed25519', require: false
  gem 'sshkit', require: false
  gem 'sshkit-sudo', require: false

  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-require_tools', require: false
  gem 'rubocop-rubycw', require: false
  gem 'rubocop-thread_safety', require: false
end

group :test do
  gem 'rack-test', require: false
end

# gem 'health_bit'
