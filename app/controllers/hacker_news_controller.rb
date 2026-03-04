# frozen_string_literal: true

require 'socket'

class HackerNewsController < ApplicationController
  protect_from_forgery with: :null_session
end
