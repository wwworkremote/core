# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::Enricher do
  let(:job_posting) { create(:job_posting, target_url: "https://example.com/job/1") }

  describe ".call" do
    it "skips enrichment when target_url is blank" do
      blank_url_posting = create(:job_posting, target_url: nil)
      allow(described_class).to receive(:enrich_posting)

      described_class.call(blank_url_posting)

      expect(described_class).not_to have_received(:enrich_posting)
    end

    it "enriches when target_url is present" do
      allow(described_class).to receive(:enrich_posting)

      described_class.call(job_posting)

      expect(described_class).to have_received(:enrich_posting).with(job_posting)
    end
  end

  describe ".call_for_link" do
    it "does nothing if a job posting already exists for the url" do
      create(:job_posting, target_url: "https://example.com/existing")
      link = DiscoveryLink.create!(url: "https://example.com/existing", board_name: "generic", status: "pending")
      allow(described_class).to receive(:board_specific_extract)

      described_class.call_for_link(link)

      expect(described_class).not_to have_received(:board_specific_extract)
    end

    it "routes cord links to extract_cord_job" do
      link = DiscoveryLink.create!(url: "https://cord.com/jobs/1", board_name: "Cord", status: "pending")
      allow(described_class).to receive(:extract_cord_job)

      described_class.call_for_link(link)

      expect(described_class).to have_received(:extract_cord_job).with(link)
    end

    it "routes non-cord links to extract_generic_job" do
      link = DiscoveryLink.create!(url: "https://example.com/jobs/1", board_name: "Indeed", status: "pending")
      allow(described_class).to receive(:extract_generic_job)

      described_class.call_for_link(link)

      expect(described_class).to have_received(:extract_generic_job).with(link)
    end
  end

  describe ".extract_cord_job" do
    let(:link) { DiscoveryLink.create!(url: "https://cord.com/jobs/12345", board_name: "Cord", status: "pending") }

    it "creates a job posting from the Cord API when the listing id is found" do
      stub_request(:get, "https://cord.com/api/v2/public/position/12345").to_return(
        status: 200,
        body: {
          data: { "position" => "Ruby Engineer", "companyName" => "Cord Co", "jobDescription" => "desc",
                  "locationCity" => "Remote" }
        }.to_json
      )

      expect { described_class.extract_cord_job(link) }.to change(JobPosting, :count).by(1)

      posting = JobPosting.last
      expect(posting.title).to eq("Ruby Engineer")
      expect(posting.signature).to eq(Digest::SHA256.hexdigest("cord-12345"))
      expect(link.reload.status).to eq("processed")
    end

    it "falls back to generic extraction when the Cord API call fails" do
      stub_request(:get, "https://cord.com/api/v2/public/position/12345").to_return(status: 500)
      allow(described_class).to receive(:extract_generic_job)

      described_class.extract_cord_job(link)

      expect(described_class).to have_received(:extract_generic_job).with(link)
    end

    it "falls back to generic extraction when no listing id is present in the url" do
      no_id_link = DiscoveryLink.create!(url: "https://cord.com/careers", board_name: "Cord", status: "pending")
      allow(described_class).to receive(:extract_generic_job)

      described_class.extract_cord_job(no_id_link)

      expect(described_class).to have_received(:extract_generic_job).with(no_id_link)
    end
  end

  describe ".extract_generic_job" do
    let(:link) { DiscoveryLink.create!(url: "https://example.com/jobs/1", board_name: "Indeed", status: "pending") }

    it "creates a job posting from the canonically-extracted data" do
      fetch_result = { content: "<html></html>", final_url: link.url, fetch_mode: "playwright" }
      extracted = { title: "Staff Engineer", company: "Acme", body: "desc", location: "Remote" }
      stub_canonical_extraction(fetch_result, extracted)

      expect { described_class.extract_generic_job(link) }.to change(JobPosting, :count).by(1)

      posting = JobPosting.last
      expect(posting.title).to eq("Staff Engineer")
      expect(link.reload.status).to eq("processed")
    end

    it "does nothing when the page fetch fails" do
      allow(JobFetchers::PageFetch).to receive(:new).and_return(instance_double(JobFetchers::PageFetch, call: nil))

      expect { described_class.extract_generic_job(link) }.not_to change(JobPosting, :count)
    end
  end

  describe ".enrich_posting" do
    it "updates job posting with extracted data" do
      fetch_result = { content: "<html></html>", final_url: "https://example.com/job/1", fetch_mode: "playwright" }
      extracted = { title: "Senior Ruby Engineer", company: "Tech Corp", body: "Full job description.",
                    location: "Remote" }
      stub_canonical_extraction(fetch_result, extracted)

      described_class.enrich_posting(job_posting)

      expect(enriched_job_posting).to have_attributes(body: "Full job description.", crawl_status: "enriched")
      expect(enriched_job_posting.enriched_at).to be_present
    end

    def enriched_job_posting
      job_posting.reload
    end
  end

  def stub_canonical_extraction(fetch_result, extracted)
    allow(JobFetchers::PageFetch).to receive(:new)
      .and_return(instance_double(JobFetchers::PageFetch, call: fetch_result))
    allow(JobFetchers::CanonicalJobExtractor).to receive(:new)
      .and_return(instance_double(JobFetchers::CanonicalJobExtractor, call: extracted))
  end
end
