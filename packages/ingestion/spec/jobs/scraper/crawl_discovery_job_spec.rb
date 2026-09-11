# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::CrawlDiscoveryJob do
  let(:board) { "BuiltIn" }
  let(:url) { "https://builtin.com/jobs" }
  let(:selector) { ".job-card" }

  it "delegates to Crawler::Discovery" do
    discovery_double = instance_double(Scraper::Crawler::Discovery)
    allow(Scraper::Crawler::Discovery).to receive(:new).and_return(discovery_double)
    allow(discovery_double).to receive(:call)

    described_class.perform_now(board, url, selector)

    expect(Scraper::Crawler::Discovery).to have_received(:new).with(board, url, selector: selector)
    expect(discovery_double).to have_received(:call)
  end

  it "skips execution if pipelines are paused" do
    allow(SystemSetting).to receive(:paused?).and_return(true)
    allow(Scraper::Crawler::Discovery).to receive(:new)

    described_class.perform_now(board, url, selector)

    expect(Scraper::Crawler::Discovery).not_to have_received(:new)
  end
end
