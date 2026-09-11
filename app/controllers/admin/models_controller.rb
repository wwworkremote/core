# frozen_string_literal: true

class Admin::ModelsController < Admin::ApplicationController
  def index
    @models = Model.order(:provider, :model_id).page(params[:page]).per(30)
  end

  def show
    @model = Model.find(params.expect(:id))
  end
end
