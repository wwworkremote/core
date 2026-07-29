# frozen_string_literal: true

require "rails_helper"

RSpec.describe HackerNews::FetchJobstoryJob do
  let!(:source) { create(:job_boards_source, slug: "hackernews") }
  let!(:query) { create(:job_boards_query, job_boards_source: source) }
  let(:jobstory_id) { 999_888 }
  let(:item_url) { "https://hacker-news.firebaseio.com/v0/item/#{jobstory_id}.json" }

  before do
    allow(JobBoards::Syncer).to receive(:new).and_return(instance_double(JobBoards::Syncer, call: true))
  end

  it "creates a new Document and triggers a sync for a job story" do
    stub_request(:get, item_url).to_return(status: 200, body: { type: "job", title: "Remote Rubyist" }.to_json)

    expect { described_class.perform_now(jobstory_id) }.to change(JobBoards::Document, :count).by(1)

    doc = JobBoards::Document.find_by(signature: Digest::SHA256.hexdigest("hn-#{jobstory_id}"))
    expect(doc.source_id).to eq(source.id)
    expect(JobBoards::Syncer).to have_received(:new)
  end

  it "does nothing when the HN item is not a job posting" do
    stub_request(:get, item_url).to_return(status: 200, body: { type: "story", title: "Show HN" }.to_json)

    expect { described_class.perform_now(jobstory_id) }.not_to change(JobBoards::Document, :count)
  end

  it "does nothing when the HTTP request fails" do
    stub_request(:get, item_url).to_return(status: 500)

    expect { described_class.perform_now(jobstory_id) }.not_to change(JobBoards::Document, :count)
  end

  it "skips silently when the hackernews source is locked" do
    Rails.cache.write("api_guard:hackernews:locked_until", 1.hour.from_now)

    expect { described_class.perform_now(jobstory_id) }.not_to change(JobBoards::Document, :count)
    expect(JobBoards::Syncer).not_to have_received(:new)
  end

  it "does not create a duplicate Document for a signature already on file" do
    stub_request(:get, item_url).to_return(status: 200, body: { type: "job", title: "Remote Rubyist" }.to_json)
    create(:job_boards_document, job_boards_source: source, job_boards_query: query,
                                 signature: Digest::SHA256.hexdigest("hn-#{jobstory_id}"))

    expect { described_class.perform_now(jobstory_id) }.not_to change(JobBoards::Document, :count)
    expect(JobBoards::Syncer).to have_received(:new)
  end

  it "accepts explicit source_id/query_id and skips the Source/Query lookup" do
    other_source = create(:job_boards_source, slug: "other")
    other_query = create(:job_boards_query, job_boards_source: other_source)
    stub_request(:get, item_url).to_return(status: 200, body: { type: "job", title: "Remote Rubyist" }.to_json)

    described_class.perform_now(jobstory_id, other_source.id, other_query.id)

    doc = JobBoards::Document.find_by(signature: Digest::SHA256.hexdigest("hn-#{jobstory_id}"))
    expect(doc.source_id).to eq(other_source.id)
  end
end
