# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Job Ingestion to AI Alignment Flow' do
  let(:source) { JobBoards::Source.find_or_create_by!(slug: 'test-board') { |s| s.name = 'Test Board' } }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }
  let(:doc_signature) { 'test-job-123' }
  let(:document_data) do
    {
      title: 'Senior Ruby Engineer',
      description: 'We are looking for a Rubyist who loves testing.',
      url: 'https://example.com/jobs/123',
      company: 'Test Corp',
      location: 'Remote',
      created_at: Time.current.to_i
    }
  end

  before do
    # Mock LLM responses
    allow(JobBoards::Categorizer).to receive(:new).and_return(double(call: true))
    allow(JobBoards::Embedder).to receive(:new).and_return(double(call: true))
  end

  it 'processes a new document all the way to a job posting' do
    # 1. Create a raw document
    doc = JobBoards::Document.create!(
      source_id: source.id,
      job_boards_query_id: query.id,
      signature: doc_signature,
      document: document_data.to_json,
      aasm_state: 'pending'
    )

    # 2. Run the Syncer
    syncer = JobBoards::Syncer.new
    expect { syncer.call(limit: 1) }.to change(JobPosting, :count).by(1)

    # 3. Verify the JobPosting attributes
    job = JobPosting.last
    expect(job.title).to eq('Senior Ruby Engineer')
    expect(job.company).to eq('Test Corp')

    # 4. Verify Document state changed
    expect(doc.reload.aasm_state).to eq('processed')

    # 5. Run Enrichment manually
    allow(JobFetchers::UrlResolver).to receive(:resolve).and_return(job.target_url)

    page_fetch_double = instance_double(JobFetchers::PageFetch)
    allow(JobFetchers::PageFetch).to receive(:new).with(job.target_url).and_return(page_fetch_double)
    allow(page_fetch_double).to receive(:call).and_return({
                                                            final_url: job.target_url,
                                                            content: "<html><body><h1>#{job.title}</h1><div class='description'>#{document_data[:description]}</div></body></html>"
                                                          })

    JobBoards::ContentEnrichmentJob.new.send(:enrich_job, job)

    job.reload
    expect(job.crawl_status).to eq('enriched')
    expect(job.body).to include('We are looking for a Rubyist')
    expect(job.enriched_at).to be_present
  end
end
