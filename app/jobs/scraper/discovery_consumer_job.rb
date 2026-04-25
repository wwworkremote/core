# frozen_string_literal: true

module Scraper
  class DiscoveryConsumerJob < ApplicationJob
    queue_as :light
    mediumweight!

    def perform
      # Pick up pending links and process them
      DiscoveryLink.where(status: 'pending').find_each do |link|
        link.update!(status: 'processing')
        begin
          Scraper::Enricher.call_for_link(link)
        rescue StandardError => e
          link.update!(status: 'error', error_message: e.message)
        end
      end
    end
  end
end
