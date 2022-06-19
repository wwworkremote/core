# frozen_string_literal: true

# # This file is used by Rack-based servers to start the application.
#
# require_relative 'config/environment'
#
# run Rails.application
# Rails.application.load_server

# cat config.ru
require 'roda'

class App < Roda
  route do |r|
    # GET / request
    r.root do
      r.redirect '/hello'
    end

    # /hello branch
    r.on 'hello' do
      # Set variable for all routes in /hello branch
      @greeting = 'Hello'

      # GET /hello/world request
      r.get 'world' do
        "#{@greeting} world!"
      end

      # /hello request
      r.is do
        # GET /hello request
        r.get do
          "#{@greeting}!"
        end

        # POST /hello request
        r.post do
          puts "Someone said #{@greeting}!"
          r.redirect
        end
      end
    end
  end
end

run App.freeze.app
