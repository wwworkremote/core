# frozen_string_literal: true

class Admin::EmailImportRecordsController < Admin::ApplicationController
  def index
    @records = EmailImportRecord.order(created_at: :desc).page(params[:page]).per(30)
  end

  def show
    @record = EmailImportRecord.find(params[:id])
  end
end
