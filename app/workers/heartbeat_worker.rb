# frozen_string_literal: true

class HeartbeatWorker
  include Sidekiq::Worker

  sidekiq_options(queue: :heartbeat)

  def perform
    Rails.logger.info { "Hello | #{Nodes.current} | #{Time.zone.now}" }
  end
end
