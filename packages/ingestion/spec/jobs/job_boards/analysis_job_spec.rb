# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::AnalysisJob do
  let(:job_posting) { create(:job_posting, status: "none") }

  it "runs Categorizer and Embedder for a normal posting" do
    categorizer = instance_double(JobBoards::Categorizer, call: true)
    embedder = instance_double(JobBoards::Embedder, call: true)
    allow(JobBoards::Categorizer).to receive(:new).with(job_posting).and_return(categorizer)
    allow(JobBoards::Embedder).to receive(:new).with(job_posting).and_return(embedder)

    described_class.perform_now(job_posting.id)

    expect(categorizer).to have_received(:call)
    expect(embedder).to have_received(:call)
  end

  it "does nothing for a job_posting_id that no longer exists" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end

  # TASK-54: GeocodingJob (:light queue, fast) can auto-ignore a posting via
  # enforce_commute_zone before this job (:heavy queue, slow) actually
  # executes, even though both get enqueued around the same moment.
  it "skips Categorizer/Embedder entirely when the posting is already ignored by execution time" do
    job_posting.ignore!
    allow(JobBoards::Categorizer).to receive(:new)
    allow(JobBoards::Embedder).to receive(:new)

    described_class.perform_now(job_posting.id)

    expect(JobBoards::Categorizer).not_to have_received(:new)
    expect(JobBoards::Embedder).not_to have_received(:new)
  end
end
