# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Syncer, type: :service do
  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "remotive", name: "Remotive") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }
  let(:job_data) do
    {
      id: "123",
      title: "Ruby Developer",
      description: "Cool job",
      url: "https://example.com/job",
      publication_date: "2024-01-01T12:00:00Z",
      company_name: "Acme Corp",
      candidate_required_location: "Worldwide"
    }
  end
  let(:document) do
    JobBoards::Document.create!(
      signature: "remotive-123",
      source_id: source.id,
      job_boards_query_id: query.id,
      document: job_data.to_json
    )
  end

  describe "#call" do
    it "creates a JobPosting from a JobBoards::Document" do
      document # Ensure document exists
      expect {
        service.call
      }.to change(JobPosting, :count).by(1)

      posting = JobPosting.last
      expect(posting.title).to eq("Ruby Developer")
      expect(posting.company_name).to eq("Acme Corp")
      expect(posting.signature).to eq("remotive-123")
    end

    it "is idempotent" do
      document # Ensure document exists
      service.call
      expect {
        service.call
      }.not_to change(JobPosting, :count)
    end

    context "when QualityFilter rejects the posting (e.g. a non-Engineering title)" do
      let(:job_data) do
        {
          id: "456",
          title: "Account Executive",
          description: "Cool sales job",
          url: "https://example.com/job",
          publication_date: "2024-01-01T12:00:00Z",
          company_name: "Acme Corp",
          candidate_required_location: "Worldwide"
        }
      end
      let(:document) do
        JobBoards::Document.create!(
          signature: "remotive-456", source_id: source.id, job_boards_query_id: query.id, document: job_data.to_json
        )
      end

      before { ActiveJob::Base.queue_adapter = :test }

      it "still ingests the posting as ignored, but never enqueues the expensive AnalysisJob" do
        document
        expect {
          service.call
        }.to change(JobPosting, :count).by(1).and have_enqueued_job(JobBoards::AnalysisJob).exactly(0).times

        expect(JobPosting.last.status).to eq("ignored")
      end
    end
  end
end
