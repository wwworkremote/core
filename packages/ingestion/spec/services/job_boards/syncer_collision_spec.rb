# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Syncer do
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "test-board") { |s| s.name = "Test Board" } }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }
  let(:syncer) { described_class.new }

  describe "Collision handling" do
    let(:signature) { "collision-123" }
    let(:document_data) { { title: "Job 1", url: "http://example.com/1" }.to_json }

    before do
      # Stub AI and Enrichment to keep it fast
      allow(JobBoards::Categorizer).to receive(:new).and_return(double(call: true))
      allow(JobBoards::Embedder).to receive(:new).and_return(double(call: true))
    end

    it "handles existing job postings with the same signature gracefully" do
      # 1. Create an existing job posting
      create(:job_posting, signature: signature, title: "Original Job")

      # 2. Create a document with the same signature
      JobBoards::Document.create!(
        source_id: source.id,
        job_boards_query_id: query.id,
        signature: signature,
        document: document_data,
        aasm_state: "pending"
      )

      # 3. Run syncer
      expect {
        syncer.call
      }.not_to raise_error

      # 4. Verify side effects
      expect(JobPosting.count).to eq(1)
      expect(JobPosting.last.title).to eq("Original Job") # Should not have been overwritten by "Job 1"
      expect(JobBoards::Document.last.aasm_state).to eq("processed")
    end

    it "handles purged jobs by marking document as processed without recreating" do
      # 1. Create a purged job
      job = create(:job_posting, signature: signature, status: "purged")

      # 2. Create document
      JobBoards::Document.create!(
        source_id: source.id,
        job_boards_query_id: query.id,
        signature: signature,
        document: document_data,
        aasm_state: "pending"
      )

      # 3. Run syncer
      syncer.call

      # 4. Verify
      job.reload
      expect(job.status).to eq("purged")
      expect(JobPosting.count).to eq(1)
      expect(JobBoards::Document.last.aasm_state).to eq("processed")
    end
  end
end
