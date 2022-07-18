# frozen_string_literal: true

# require 'rack/unreloader'
#
# Unreloader = Rack::Unreloader.new(subclasses: %w[Roda]) { App }
# # Unreloader = Rack::Unreloader.new { App }
# Unreloader.require './app.rb'
#
# run Unreloader

require './app'
run Sinatra::Application
