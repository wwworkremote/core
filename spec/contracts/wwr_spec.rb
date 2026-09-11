# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WWR Live Contract", type: :request do
  # We use :live tag to bypass VCR if configured to do so,
  # or we manually disable VCR for this spec.

  it "fetches a valid RSS feed from We Work Remotely", :live do
    VCR.turned_off do
      WebMock.allow_net_connect!

      response = Faraday.get("https://weworkremotely.com/remote-jobs.rss")
      expect(response.status).to eq(200)

      feed = Feedjira.parse(response.body)
      expect(feed.entries).not_to be_empty

      entry = feed.entries.first
      expect(entry.title).to be_present
      expect(entry.url).to be_present
      expect(entry.entry_id).to be_present

      WebMock.disable_net_connect!
    end
  end
end
