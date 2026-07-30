# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Auditor do
  before do
    ActiveJob::Base.queue_adapter = :test
    allow(JobBoards::Categorizer).to receive(:new).and_return(instance_double(JobBoards::Categorizer, call: nil))
    allow(JobBoards::Embedder).to receive(:new).and_return(instance_double(JobBoards::Embedder, call: nil))
    default_filter = instance_double(JobBoards::QualityFilter, useful?: true)
    allow(JobBoards::QualityFilter).to receive(:new).and_return(default_filter)
    allow(JobBoards::Syncer).to receive(:new).and_return(instance_double(JobBoards::Syncer, sync_document: nil))
  end

  describe "#call" do
    it "counts and fixes documents missing a posting" do
      create(:job_boards_document)

      stats = described_class.new(fix: true, limit: 10).call

      expect(stats[:missing_postings]).to eq(1)
      expect(stats[:fixed]).to eq(1)
    end

    it "does not attempt a fix when fix: false" do
      create(:job_boards_document)

      stats = described_class.new(fix: false).call

      expect(stats[:missing_postings]).to eq(1)
      expect(stats[:fixed]).to eq(0)
    end

    it "counts postings missing an AI category and categorizes them" do
      jp = create(:job_posting, data: {})
      categorizer = instance_double(JobBoards::Categorizer, call: nil)
      allow(JobBoards::Categorizer).to receive(:new).with(jp).and_return(categorizer)

      stats = described_class.new(fix: true, limit: 10).call

      expect(stats[:missing_category]).to eq(1)
      expect(categorizer).to have_received(:call)
    end

    it "counts postings missing an embedding and embeds them" do
      jp = create(:job_posting, embedding: nil)
      embedder = instance_double(JobBoards::Embedder, call: nil)
      allow(JobBoards::Embedder).to receive(:new).with(jp).and_return(embedder)

      stats = described_class.new(fix: true, limit: 10).call

      expect(stats[:missing_embedding]).to eq(1)
      expect(embedder).to have_received(:call)
    end

    it "counts postings missing geocoding and enqueues it" do
      jp = create(:job_posting, latitude: nil, location: "Remote")

      stats = nil
      expect {
        stats = described_class.new(fix: true, limit: 10).call
      }.to have_enqueued_job(JobBoards::GeocodingJob).with(jp.id)

      expect(stats[:missing_geocoding]).to eq(1)
    end

    it "marks low-quality postings as ignored via the AASM event" do
      jp = create(:job_posting)
      filter = instance_double(JobBoards::QualityFilter, useful?: false)
      allow(JobBoards::QualityFilter).to receive(:new).with(jp).and_return(filter)

      described_class.new(fix: true, limit: 10).call

      expect(jp.reload.status).to eq("ignored")
    end

    it "skips the ignore fix when the posting cannot transition to ignored" do
      jp = create(:job_posting, status: "favorited")
      filter = instance_double(JobBoards::QualityFilter, useful?: false)
      allow(JobBoards::QualityFilter).to receive(:new).with(jp).and_return(filter)

      expect { described_class.new(fix: true, limit: 10).call }.not_to raise_error

      expect(jp.reload.status).to eq("favorited")
    end

    it "stops fixing once the limit is reached" do
      create_list(:job_boards_document, 3)

      stats = described_class.new(fix: true, limit: 2).call

      expect(stats[:missing_postings]).to eq(3)
      expect(stats[:fixed]).to eq(2)
    end
  end
end
