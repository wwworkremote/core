# frozen_string_literal: true

class Admin::EventsController < Admin::ApplicationController
  def index
    @events = Ahoy::Event.order(time: :desc).includes(:visit).page(params[:page]).per(50)
  end

  def show
    @event = Ahoy::Event.find(params.expect(:id))
  end
end
