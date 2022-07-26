# frozen_string_literal: true

class NodesController < ApplicationController # :nodoc:
  def index
    render json: Nodes.representation.to_json
  end
end
