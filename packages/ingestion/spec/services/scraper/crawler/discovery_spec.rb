# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::Crawler::Discovery do
  let(:board_name) { "test-board" }
  let(:base_url) { "http://example.com/jobs" }
  let(:discovery) { described_class.new(board_name, base_url) }

  describe "#call" do
    it "handles Playwright errors gracefully" do
      # Stub Playwright to raise an error
      allow(Playwright).to receive(:create).and_raise(Playwright::Error.new(message: "Timeout!"))

      expect(Rails.logger).to receive(:error).with(/Playwright error/)

      expect {
        discovery.call
      }.not_to raise_error
    end

    it "handles unexpected errors gracefully" do
      allow(Playwright).to receive(:create).and_raise(StandardError.new("Boom!"))

      expect(Rails.logger).to receive(:error).with(/Unexpected error/)

      expect {
        discovery.call
      }.not_to raise_error
    end
  end
end
