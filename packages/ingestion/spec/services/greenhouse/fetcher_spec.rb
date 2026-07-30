# frozen_string_literal: true

require "rails_helper"

RSpec.describe Greenhouse::Fetcher, type: :service do
  include ActiveJob::TestHelper

  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "greenhouse", name: "Greenhouse") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  describe "#call" do
    before do
      ActiveJob::Base.queue_adapter = :test
      source
      query.update!(data: { "boards" => %w[stripe], "terms" => ["ruby"] })
    end

    it "enqueues one granular fetch job per board/term combination" do
      expect { service.call(force: true) }
        .to have_enqueued_job(JobBoards::GranularFetchJob)
        .with("Greenhouse::Fetcher", "stripe", "ruby", { source_id: source.id, query_id: query.id })
    end
  end

  describe "#fetch_granular" do
    before { query }

    it "stores each job returned by the board as a document" do
      stub_request(:get, /boards-api.greenhouse.io/)
        .to_return(status: 200, body: { "jobs" => [{ "id" => "1", "title" => "Remote Ruby Engineer" }] }.to_json)

      service.fetch_granular("stripe", "", source.id, query.id)

      doc = JobBoards::Document.find_by(signature: "greenhouse-stripe-1")
      expect(doc).to be_present
      expect(JSON.parse(doc.document)["board_slug"]).to eq("stripe")
    end

    it "does not create documents when the response is not successful" do
      stub_request(:get, /boards-api.greenhouse.io/).to_return(status: 500)

      expect { service.fetch_granular("stripe", "", source.id, query.id) }
        .not_to change(JobBoards::Document, :count)
    end
  end
end
