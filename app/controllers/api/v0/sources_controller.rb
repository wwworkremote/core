# frozen_string_literal: true

class Api::V0::SourcesController < ApiController
  def index
    page = params.fetch("page", 1)

    render json: Source.order(id: :desc).page(page).without_count
  end

  def show
    id = params[:id]

    render json: Source.find(id)
  end
end
