# frozen_string_literal: true

require "rails_helper"

module Scraper
  # Minimal stand-in classes, namespaced the same way (Scraper::Board::ApiClient)
  # as the four real ApiClients (Dice, Indeed, Glassdoor, LinkedIn), to test the
  # prepend-based wrapping in isolation from any of their real scraping logic.
  #
  # Nested (not compact) on purpose: `class TestBoard::ApiClient` would need
  # TestBoard to already exist as a module, which it doesn't here.
  # rubocop:disable Style/ClassAndModuleChildren
  module TestBoard
    class ApiClient
      prepend Scraper::Traceable

      def search(keywords, _location)
        { success: true, count: keywords.length }
      end
    end
  end

  module FailingTestBoard
    class ApiClient
      prepend Scraper::Traceable

      def search(_keywords, _location)
        { success: false, error: "Fetch failed" }
      end
    end
  end
  # rubocop:enable Style/ClassAndModuleChildren
end

RSpec.describe Scraper::Traceable do
  let(:fake_span) { instance_double(OpenTelemetry::Trace::Span, set_attribute: nil, "status=": nil) }
  let(:fake_tracer) { instance_double(OpenTelemetry::Trace::Tracer) }

  before do
    allow(OpenTelemetry.tracer_provider).to receive(:tracer).with("scraper").and_return(fake_tracer)
    allow(fake_tracer).to receive(:in_span).and_yield(fake_span)
  end

  it "wraps #search in a span carrying board/keywords/location, without changing the return value" do
    result = Scraper::TestBoard::ApiClient.new.search("Ruby", "Remote")

    expect(result).to eq(success: true, count: 4)
    expect(fake_tracer).to have_received(:in_span).with(
      "scraper.search",
      attributes: {
        "app.scraper.board" => "test_board",
        "app.scraper.keywords" => "Ruby",
        "app.scraper.location" => "Remote"
      }
    )
    expect(fake_span).to have_received(:set_attribute).with("app.scraper.success", true)
    expect(fake_span).to have_received(:set_attribute).with("app.scraper.count", 4)
  end

  it "marks the span as errored without swallowing the error result" do
    result = Scraper::FailingTestBoard::ApiClient.new.search("Ruby", "Remote")

    expect(result).to eq(success: false, error: "Fetch failed")
    expect(fake_span).to have_received(:set_attribute).with("app.scraper.success", false)
    expect(fake_span).to have_received(:status=)
  end
end
