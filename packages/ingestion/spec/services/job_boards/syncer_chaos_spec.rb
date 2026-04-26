# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Syncer do
  let(:source) { create(:job_boards_source) }
  let(:query) { create(:job_boards_query, job_boards_source: source) }
  let(:syncer) { described_class.new }

  before do
    allow(JobBoards::Categorizer).to receive(:new).and_return(double(call: true))
    allow(JobBoards::Embedder).to receive(:new).and_return(double(call: true))
  end

  describe "Chaos HTML handling" do
    it "handles completely broken HTML gracefully" do
      JobBoards::Document.create!(
        job_boards_source: source,
        job_boards_query: query,
        signature: "chaos-1",
        document: { title: "Chaos Job", url: "http://example.com/chaos", body: "<div<<<>>invalid" }.to_json,
        aasm_state: "pending"
      )

      expect { syncer.call }.not_to raise_error
      expect(JobPosting.last.body).to be_present
    end

    it "handles deeply nested HTML without stack level too deep" do
      deep_html = "<div>" * 100 + "Deep Job" + "</div>" * 100
      JobBoards::Document.create!(
        job_boards_source: source,
        job_boards_query: query,
        signature: "chaos-2",
        document: { title: "Deep Job", url: "http://example.com/deep", body: deep_html }.to_json,
        aasm_state: "pending"
      )

      expect { syncer.call }.not_to raise_error
    end

    it "handles empty body by still creating the record" do
      JobBoards::Document.create!(
        job_boards_source: source,
        job_boards_query: query,
        signature: "chaos-3",
        document: { title: "Empty Job", url: "http://example.com/empty", body: "" }.to_json,
        aasm_state: "pending"
      )

      syncer.call
      expect(JobPosting.find_by(signature: "chaos-3")).to be_present
    end
  end
end
