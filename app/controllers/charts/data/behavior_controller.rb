# frozen_string_literal: true

module Charts
  module Data
    class BehaviorController < ApplicationController
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
  end
end
