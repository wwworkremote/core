# frozen_string_literal: true

class Charts::Data::SourcesController < ApplicationController
  def index
    @days = requested_days
    render json: Source.where(created_at: @days.days.ago..).group_by_day(:created_at).count
  end

  private

  def requested_days
    days = Integer(params["days"] || 1)
    days.positive? ? days : 1
  end
end
