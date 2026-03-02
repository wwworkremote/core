# frozen_string_literal: true

module API
  module V0
    class SourcesController < APIController
      def index
        page = params.fetch('page', 1)

        render json: Source.order(id: :desc).page(page).without_count
      end

      def show
        id = params[:id]

        render json: Source.find(id)
      end
    end
  end
end
