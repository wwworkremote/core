# frozen_string_literal: true

class Api::CompaniesController < ApplicationController
  def search
    matches = Companies::FuzzyMatcher.call(params[:q].to_s)
    render json: matches.as_json(only: %i[id name slug status])
  end
end
