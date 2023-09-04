# frozen_string_literal: true

class HackerNewsController < ApplicationController
  protect_from_forgery with: :null_session

  def fetch_jobstory
    jobstory_id = params[:jobstory_id]
    wait_until = params[:wait_until]

    Rails.logger.info { "#{self.class.name}##{__method__} ==>> jobstory_id:#{jobstory_id}, wait_until:#{wait_until}" }

    HackerNews::FetchJobstoryWorker
      .set(wait_until:)
      .perform_async(jobstory_id)

    render json: { jobstory_id:, wait_until: }
  end
end
