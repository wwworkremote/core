# frozen_string_literal: true

require 'socket'

class HackerNewsController < ApplicationController
  protect_from_forgery with: :null_session

  def fetch_jobstory
    Rails.logger.debug { params.ai }

    jobstory_id = params[:jobstory_id]
    wait_for = params[:wait_for]
    wait_until = wait_for.seconds

    Rails.logger.info { "#{self.class.name}##{__method__} ==>> jobstory_id:#{jobstory_id}, wait_for:#{wait_for}, wait_until:#{wait_until}" }

    sidekiq_id = HackerNews::FetchJobstoryWorker
                 .set(wait_until:)
                 .perform_async(jobstory_id)

    node = Socket.gethostname
    render json: { sidekiq_id:, jobstory_id:, wait_for:, wait_until:, node: }
  end
end
