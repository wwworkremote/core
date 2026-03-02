# frozen_string_literal: true

module Charts
  module Data
    class SourcesController < ApplicationController
      def index
        @days = Integer(params['days'] || 1)
        @days = 1 unless @days.positive?

        render json: Source.where(created_at: @days.days.ago..).group_by_day(:created_at).count
      end
    end
  end
end
