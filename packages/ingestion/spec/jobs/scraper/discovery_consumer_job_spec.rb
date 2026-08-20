# frozen_string_literal: true

require "rails_helper"

# TASK-74: this job existed but was never wired into config/recurring.yml,
# so pending DiscoveryLinks (created by CrawlDiscoveryJob) piled up forever
# and never became JobPostings. Covers the actual draining behavior now that
# it's scheduled.
RSpec.describe Scraper::DiscoveryConsumerJob do
  let!(:pending_link) { create(:discovery_link, status: "pending") }

  it "processes pending discovery links via Enricher" do
    allow(Scraper::Enricher).to receive(:call_for_link)

    described_class.perform_now

    expect(Scraper::Enricher).to have_received(:call_for_link).with(pending_link)
  end

  it "ignores links that are not pending" do
    processed_link = create(:discovery_link, status: "processed", url: "https://example.com/other-job")
    allow(Scraper::Enricher).to receive(:call_for_link)

    described_class.perform_now

    expect(Scraper::Enricher).not_to have_received(:call_for_link).with(processed_link)
  end

  it "marks the link as errored (without raising) if Enricher fails" do
    allow(Scraper::Enricher).to receive(:call_for_link).and_raise(StandardError, "boom")

    described_class.perform_now

    expect(pending_link.reload).to have_attributes(status: "error", error_message: "boom")
  end
end
