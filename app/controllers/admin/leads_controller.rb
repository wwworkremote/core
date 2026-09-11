# frozen_string_literal: true

class Admin::LeadsController < Admin::ApplicationController
  def index
    @leads = Lead.order(created_at: :desc).page(params[:page]).per(30)
  end

  def show
    @lead = Lead.find(params.expect(:id))
  end
end
