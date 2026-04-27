# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::CrawlDiscoveryJob, type: :job do
  let(:board) { "BuiltIn" }
  let(:url) { "https://builtin.com/jobs" }
  let(:selector) { ".job-card" }

  it "delegates to Crawler::Discovery" do
    discovery_double = instance_double(Scraper::Crawler::Discovery)
    expect(Scraper::Crawler::Discovery).to receive(:new)
      .with(board, url, selector: selector)
      .and_return(discovery_double)
    expect(discovery_double).to receive(:call)

    described_class.perform_now(board, url, selector)
  end

  it "skips execution if pipelines are paused" do
    allow(SystemSetting).to receive(:paused?).and_return(true)
    expect(Scraper::Crawler::Discovery).not_to receive(:new)

    described_class.perform_now(board, url, selector)
  end
end
