# frozen_string_literal: true

module Admin
  class EmailImportRecordsController < Admin::ApplicationController
    def index
      @records = EmailImportRecord.order(created_at: :desc).page(params[:page]).per(30)
    end

    def show
      @record = EmailImportRecord.find(params[:id])
    end
  end
end
