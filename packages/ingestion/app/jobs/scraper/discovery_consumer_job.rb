# frozen_string_literal: true

class Scraper::DiscoveryConsumerJob < ApplicationJob
  queue_as :light
  mediumweight!

  def perform
    # Pick up pending links and process them
    DiscoveryLink.where(status: "pending").find_each { |link| process_link(link) }
  end

  private

  # rubocop:disable Metrics/MethodLength
  def process_link(link)
    check_cancellation!
    link.update!(status: "processing")

    begin
      Scraper::Enricher.call_for_link(link)
    rescue StandardError => e
      link.update!(status: "error", error_message: e.message)
    end
  end
  # rubocop:enable Metrics/MethodLength
end
