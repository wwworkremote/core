# frozen_string_literal: true

class Charts::Data::BehaviorController < ApplicationController
  def visits
    render json: Ahoy::Visit.group_by_day(:started_at).count
  end

  def events
    render json: Ahoy::Event.group(:name).count
  end

  def referrers
    render json: Ahoy::Visit.group(:referring_domain).count
  end
end
