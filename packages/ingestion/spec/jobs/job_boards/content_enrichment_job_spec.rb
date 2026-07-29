# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::ContentEnrichmentJob do
  let!(:job) { create(:job_posting, body: nil, target_url: "https://example.com/jobs/1") }

  let(:fetch_result) { { content: "<html></html>", final_url: "https://example.com/jobs/1" } }

  def stub_extraction(job_data)
    allow(JobFetchers::CanonicalJobExtractor)
      .to receive(:new).and_return(instance_double(JobFetchers::CanonicalJobExtractor, call: job_data))
  end

  before do
    allow(JobFetchers::UrlResolver).to receive(:resolve).and_return(job.target_url)
    page_fetch = instance_double(JobFetchers::PageFetch, call: fetch_result)
    allow(JobFetchers::PageFetch).to receive(:new).and_return(page_fetch)
    allow(JobBoards::Categorizer).to receive(:new).and_return(instance_double(JobBoards::Categorizer, call: true))
    allow(JobBoards::Embedder).to receive(:new).and_return(instance_double(JobBoards::Embedder, call: true))
  end

  it "skips entirely when pipelines are paused" do
    allow(SystemSetting).to receive(:paused?).and_return(true)

    described_class.perform_now

    expect(JobFetchers::UrlResolver).not_to have_received(:resolve)
  end

  it "enriches, categorizes, and embeds a job when a description is found" do
    stub_extraction(description: "<p>Great <b>role</b>.</p>")

    described_class.perform_now

    job.reload
    expect(job.body).to eq("Great **role**.")
    expect(job.crawl_status).to eq("enriched")
    expect(job.enriched_at).to be_present
    expect(JobBoards::Categorizer).to have_received(:new).with(job)
    expect(JobBoards::Embedder).to have_received(:new).with(job)
  end

  it "marks the job blocked when extraction returns nil" do
    stub_extraction(nil)

    described_class.perform_now

    expect(job.reload.crawl_status).to eq("enrichment_blocked")
  end

  it "marks the job failed when extraction finds no description" do
    stub_extraction(description: nil)

    described_class.perform_now

    expect(job.reload.crawl_status).to eq("enrichment_failed_no_content")
  end

  it "leaves the job untouched when the page fetch fails" do
    allow(JobFetchers::PageFetch).to receive(:new).and_return(instance_double(JobFetchers::PageFetch, call: nil))

    described_class.perform_now

    expect(job.reload.crawl_status).to be_nil
  end

  it "marks the job errored when enrichment raises" do
    allow(JobFetchers::CanonicalJobExtractor).to receive(:new).and_raise(StandardError, "boom")

    described_class.perform_now

    expect(job.reload.crawl_status).to eq("enrichment_error")
  end
end
