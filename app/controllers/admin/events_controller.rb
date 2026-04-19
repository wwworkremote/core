# frozen_string_literal: true

module Admin
  class EventsController < Admin::ApplicationController
    def index
      @events = Ahoy::Event.order(time: :desc).includes(:visit).page(params[:page]).per(50)
    end

    def show
      @event = Ahoy::Event.find(params[:id])
    end
  end
end
