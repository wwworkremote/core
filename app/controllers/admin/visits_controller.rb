# frozen_string_literal: true

class Admin::VisitsController < Admin::ApplicationController
  def index
    @visits = Ahoy::Visit.order(started_at: :desc).page(params[:page]).per(30)
  end

  def show
    @visit = Ahoy::Visit.find(params.expect(:id))
    @events = @visit.events.order(time: :desc)
  end
end
