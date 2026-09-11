# frozen_string_literal: true

class Scraper::DiscoveryConsumerJob < ApplicationJob
  queue_as :light
  mediumweight!

  def perform
    # Pick up pending links and process them
    DiscoveryLink.where(status: "pending").find_each { |link| process_link(link) }
  end

  private

  # rubocop:disable-next Metrics/MethodLength
  def process_link(link)
    check_cancellation!
    link.update!(status: "processing")

    begin
      Scraper::Enricher.call_for_link(link)
      touch_last_ingested(link) if link.reload.status == "processed"
    rescue StandardError => e
      link.update!(status: "error", error_message: e.message)
    end
  end

  # Only Enricher's create_*_job_posting paths set status "processed" --
  # matches the last_ingested_at convention used by ServiceRunner/Syncer
  # (TASK-74: this pipeline never touched it, so the dashboard kept
  # showing "never ingested" even once links started draining again).
  def touch_last_ingested(link)
    JobBoards::Source.find_by(slug: link.board_name)&.update!(last_ingested_at: Time.current)
  end
end
