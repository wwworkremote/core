# frozen_string_literal: true

require "rails_helper"

RSpec.describe HackerNews::FetchLatestJobstories do
  let(:fetcher) { described_class.new }

  before { create(:job_boards_source, slug: "hackernews") }

  it "fetches jobstory ids and hands them to HackerNews::FetchJobstories" do
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/jobstories.json")
      .to_return(status: 200, body: [111, 222].to_json)

    allow(HackerNews::FetchJobstories).to receive(:new).and_call_original

    fetcher.call

    expect(HackerNews::FetchJobstories).to have_received(:new).with(hash_including(jobstory_ids: [111, 222]))
  end
end
