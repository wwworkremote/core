# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lever::Fetcher, type: :service do
  include ActiveJob::TestHelper

  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "lever", name: "Lever") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  describe "#call" do
    before do
      ActiveJob::Base.queue_adapter = :test
      source
      query.update!(data: { "sites" => %w[gitlab], "terms" => ["ruby"] })
    end

    it "enqueues one granular fetch job per site/term combination" do
      expect { service.call(force: true) }
        .to have_enqueued_job(JobBoards::GranularFetchJob)
        .with("Lever::Fetcher", "gitlab", "ruby", { source_id: source.id, query_id: query.id })
    end
  end

  describe "#fetch_granular" do
    before { query }

    it "paginates until a short page, storing each job as a document" do
      stub_request(:get, /api.lever.co.*skip=0/)
        .to_return(status: 200, body: [{ "id" => "1", "text" => "Remote Ruby Engineer" }].to_json)

      service.fetch_granular("gitlab", "", source.id, query.id)

      doc = JobBoards::Document.find_by(signature: "lever-gitlab-1")
      expect(doc).to be_present
      expect(JSON.parse(doc.document)["site_slug"]).to eq("gitlab")
    end

    it "stops without creating documents when the response is not successful" do
      stub_request(:get, /api.lever.co/).to_return(status: 500)

      expect { service.fetch_granular("gitlab", "", source.id, query.id) }
        .not_to change(JobBoards::Document, :count)
    end
  end
end
