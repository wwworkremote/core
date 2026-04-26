# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ingestion Pipeline Hardening", type: :system do
  include ActiveJob::TestHelper

  let!(:source) { JobBoards::Source.find_or_create_by!(slug: "arbeitnow") { |s| s.name = "Arbeitnow" } }
  let!(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }
  
  let(:job_data) do
    {
      slug: "senior-ruby-engineer-123",
      title: "Senior Ruby Engineer",
      description: nil, # Set to nil to trigger enrichment flow
      url: "https://example.com/jobs/123",
      company_name: "Test Corp",
      location: "Remote",
      created_at: Time.current.to_i,
      tags: ["ruby", "rails"]
    }
  end

  let(:api_response) do
    {
      data: [job_data],
      links: {},
      meta: {}
    }
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    allow_any_instance_of(JobBoards::ContentEnrichmentJob).to receive(:sleep)
    VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }
    # 1. Stub the HTTP request for the Fetcher
    stub_request(:get, Arbeitnow::Fetcher::API_URL)
      .to_return(status: 200, body: api_response.to_json, headers: { "Content-Type" => "application/json" })

    # 2. Stub AI Alignment services
    allow(JobBoards::Categorizer).to receive(:new).and_return(double(call: true))
    allow(JobBoards::Embedder).to receive(:new).and_return(double(call: true))

    # 3. Stub Enrichment network calls
    enrichment_content = "This is the full job description after enrichment."
    allow(JobFetchers::UrlResolver).to receive(:resolve).and_return(job_data[:url])
    page_fetch_double = instance_double(JobFetchers::PageFetch)
    allow(JobFetchers::PageFetch).to receive(:new).and_return(page_fetch_double)
    allow(page_fetch_double).to receive(:call).and_return({
      final_url: job_data[:url],
      content: "<html><body><div class='description'>#{enrichment_content}</div></body></html>"
    })
    
    # Ensure pipelines are not paused
    SystemSetting.create!(key: "pipelines_paused", value: "false") unless SystemSetting.find_by(key: "pipelines_paused")
  end

  after do
    VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
  end

  it "executes the full ingestion sequence from UI trigger to Enriched JobPosting" do
    # Phase A: Trigger Ingestion via UI
    visit data_fetchers_path
    
    expect(page).to have_content("Arbeitnow")
    
    # Target the Arbeitnow row specifically
    within(".bg-base-300", text: "Arbeitnow") do
      click_button "Force"
    end

    # Use a more specific selector and wait for visibility
    expect(page).to have_css(".alert-success", text: /started successfully/i, wait: 10)

    # Verify Document was created
    expect(JobBoards::Document.count).to eq(1)
    doc = JobBoards::Document.last
    expect(doc.aasm_state).to eq("processed")

    # Phase B: Verify Syncer side-effects
    expect(JobPosting.count).to eq(1)
    job = JobPosting.last
    expect(job.title).to eq("Senior Ruby Engineer")
    expect(job.company_name).to eq("Test Corp")

    # Phase C: Trigger Enrichment via UI
    visit data_fetchers_path
    expect(page).to have_text(/Pending Enrichment/i)
    
    expect {
      click_on "START_ENRICHMENT"
    }.to have_enqueued_job(JobBoards::ContentEnrichmentJob)

    perform_enqueued_jobs

    # Final Verification
    job.reload
    expect(job.crawl_status).to eq("enriched")
    expect(job.body).to include("full job description after enrichment")
    expect(job.enriched_at).to be_present
    
    visit admin_job_posting_path(job)
    expect(page).to have_text(/Senior Ruby Engineer/i)
    expect(page).to have_text(/Test Corp/i)
  end
end
