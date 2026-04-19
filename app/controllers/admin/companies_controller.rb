# frozen_string_literal: true

module Admin
  class CompaniesController < Admin::ApplicationController
    def index
      @companies = Company.order(name: :asc).page(params[:page]).per(30)
    end

    def show
      @company = Company.find(params[:id])
    end
  end
end
