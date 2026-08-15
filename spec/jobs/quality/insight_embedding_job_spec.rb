# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quality::InsightEmbeddingJob do
  include ActiveJob::TestHelper

  let(:insight) { create(:system_insight, message: "Use double quotes", tool: :rubocop) }
  let(:mock_embedding) { Array.new(768) { rand } }

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(JobBoards::Embedder).to receive(:embed_text).and_return(mock_embedding)
  end

  it "generates and updates embedding for a single insight" do
    described_class.perform_now(insight.id)
    insight.reload
    # Use match_array with precision or just check size/presence since float precision varies in DB
    expect(insight.embedding.size).to eq(768)
  end

  it "constructs descriptive text for embedding" do
    job = described_class.new
    text = job.send(:construct_text, insight)
    expect(text).to include("Tool: rubocop")
    expect(text).to include("Message: Use double quotes")
  end

  it "handles multiple pending insights when called without ID" do
    create(:system_insight, embedding: nil)
    # The after_create_commit hook will enqueue jobs, so we clear the queue for this test
    clear_enqueued_jobs

    expect {
      described_class.perform_now
    }.to have_enqueued_job(described_class)
  end

  it "logs an error if embedding generation fails" do
    allow(JobBoards::Embedder).to receive(:embed_text).and_return(nil)
    allow(Rails.logger).to receive(:error)

    described_class.perform_now(insight.id)

    expect(insight.reload.embedding).to be_nil
    expect(Rails.logger).to have_received(:error).with(/Failed to generate embedding for Insight #{insight.id}/)
  end

  it "skips if insight no longer exists" do
    expect {
      described_class.perform_now(0) # Non-existent ID
    }.not_to raise_error

    expect(JobBoards::Embedder).not_to have_received(:embed_text)
  end

  it "skips if embedding already present" do
    insight.update!(embedding: mock_embedding)

    described_class.perform_now(insight.id)

    expect(JobBoards::Embedder).not_to have_received(:embed_text)
  end
end
