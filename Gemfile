# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.2'

gem 'bcrypt', '~> 3.1.7'
gem 'faraday'
gem 'faraday-encoding'
gem 'faraday_middleware'
gem 'hiredis'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.0', require: false
gem 'rails', '~> 6.1.3', '>= 6.1.3.2'
gem 'redis', require: %w[redis redis/connection/hiredis]
gem 'typhoeus'
gem 'whenever', require: false

group :development, :test do
  gem 'byebug'
  gem 'fuubar', require: false
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails'
end

group :development do
  gem 'annotate'
  gem 'brakeman'
  gem 'capistrano', '~> 3.10', require: false
  gem 'capistrano-asdf', require: false
  gem 'capistrano-rails', '~> 1.6', require: false
  gem 'guard-rspec', require: false
  gem 'listen', '~> 3.3', require: false
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

# gem 'active_median'
# gem 'awesome_print'
# gem 'blingfire' # https://github.com/ankane/blingfire
# gem 'dry-transformer'
# gem 'eps' # https://github.com/ankane/eps
# gem 'faraday-http-cache'
# gem 'groupdate'
# gem 'hightop'
# gem 'loofah'
# gem 'memo_wise'
# gem 'mitie' # https://github.com/ankane/mitie
# gem 'notable' # https://github.com/ankane/notable
# gem 'rainbow'
# gem 'safely_block' # https://github.com/ankane/safely
# gem 'tty-box', require: false
# gem 'tty-color', require: false
# gem 'tty-command', require: false
# gem 'tty-config', require: false
# gem 'tty-cursor', require: false
# gem 'tty-editor', require: false
# gem 'tty-file', require: false
# gem 'tty-font', require: false
# gem 'tty-link', require: false
# gem 'tty-logger', require: false
# gem 'tty-markdown', require: false
# gem 'tty-option', require: false
# gem 'tty-pager', require: false
# gem 'tty-pie', require: false
# gem 'tty-platform', require: false
# gem 'tty-prompt', require: false
# gem 'tty-reader', require: false
# gem 'tty-screen', require: false
# gem 'tty-table', require: false
# gem 'tty-tree', require: false
# gem 'tty-which', require: false
# gem 'youtokentome' # https://github.com/ankane/youtokentome
gem 'deepsort'
gem 'friendly_id'
gem 'jsonb_accessor'
gem 'multi_xml'
gem 'pastel', require: false
gem 'pghero'
gem 'pg_query', '>= 0.9.0'
gem 'rails-html-sanitizer'
gem 'rollups' # https://github.com/ankane/rollup
gem 'rubypants', require: false
gem 'sanitize', require: false
gem 'scenic'
gem 'stopwords-filter', require: 'stopwords'
gem 'tty', require: false
gem 'tty-progressbar', require: false
gem 'tty-spinner', require: false
