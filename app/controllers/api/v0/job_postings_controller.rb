# frozen_string_literal: true

module Api
  module V0
    class JobPostingsController < ApiController
      def index
        page = params.fetch('page') { 1 }

        render json: JobPosting.order(id: :desc).page(page).without_count
      end

      def show
        id = params[:id]

        render json: JobPosting.find(id)
      end
    end
  end
end
