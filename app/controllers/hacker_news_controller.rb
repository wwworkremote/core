# frozen_string_literal: true

class HackerNewsController < ApplicationController
  def fetch_jobstory
    jobstory_id = parameters[:jobstory_id]
    wait_until = Integer(parameters[:wait_until]).seconds

    Rails.logger.info { "#{self.class.name}##{__method__} ==>> jobstory_id:#{jobstory_id}" }
    HackerNews::FetchJobstoryWorker
      .set(wait_until:)
      .perform_async(jobstory_id)

    render json: { jobstory_id:, wait_until: }
  end
end
