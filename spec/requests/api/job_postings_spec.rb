# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::JobPostings" do
  let!(:job_posting) { create(:job_posting) }

  before do
    allow(JobBoards::Categorizer).to receive(:new).and_return(instance_double(JobBoards::Categorizer, call: true))
    allow(JobBoards::Embedder).to receive(:new).and_return(instance_double(JobBoards::Embedder, call: true))
  end

  describe "POST /api/job_postings/:id/enrich" do
    it "uses the reviewed plain text description when present" do
      post enrich_api_job_posting_path(job_posting), params: {
        provider: "linkedin",
        extracted: { description_text: "Plain text description." }
      }

      expect(response).to be_successful
      expect(response.parsed_body["success"]).to be true
      expect(job_posting.reload.body).to eq("Plain text description.")
      expect(job_posting.crawl_status).to eq("enriched")
      expect(job_posting.enriched_at).to be_present
    end

    it "prefers the reviewed HTML description, converted to markdown, over the plain text" do
      post enrich_api_job_posting_path(job_posting), params: {
        provider: "linkedin",
        extracted: { description_text: "fallback", description_html: "<p>Rich <b>description</b>.</p>" }
      }

      expect(job_posting.reload.body).to eq("Rich **description**.")
    end

    it "falls back to CanonicalJobExtractor against the raw HTML when no reviewed text is sent" do
      html = <<~HTML
        <html><body>
          <h1 class="job-title">Remote Engineer</h1>
          <div class="job-description">Extracted description.</div>
        </body></html>
      HTML

      post enrich_api_job_posting_path(job_posting), params: {
        provider: "generic", url: "https://example.com/jobs/1", html: html
      }

      expect(response).to be_successful
      expect(job_posting.reload.body).to include("Extracted description.")
    end

    it "returns unprocessable_content when no description can be found anywhere" do
      post enrich_api_job_posting_path(job_posting), params: {
        provider: "generic", url: "https://example.com/jobs/1", html: "<html><body></body></html>"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["success"]).to be false
    end

    describe "mapping extracted fields onto their matching columns" do
      before do
        post enrich_api_job_posting_path(job_posting), params: {
          provider: "linkedin",
          extracted: {
            description_text: "Description.",
            title: "Staff Engineer",
            company: "Acme Corp",
            location: "Remote",
            apply_url: "https://acme.example/apply",
            posted_at: "2026-01-02",
            skills: "ruby, rails , postgres"
          }
        }
        job_posting.reload
      end

      it "maps simple fields" do
        expect(job_posting.title).to eq("Staff Engineer")
        expect(job_posting.company_name).to eq("Acme Corp")
        expect(job_posting.location).to eq("Remote")
        expect(job_posting.target_url).to eq("https://acme.example/apply")
      end

    it "maps derived fields" do
      expect(job_posting.published_at.to_date).to eq(Date.new(2026, 1, 2))
      expect(job_posting.tags).to eq(%w[ruby rails postgres])
    end

    it "uses the current canonical posting URL when Apply URL is blank" do
      canonical_url = "https://cengage.wd5.myworkdayjobs.com/CengageNorthAmericaCareers/job/United-States/Principal-Software-Engineer_R2026-711"

      post enrich_api_job_posting_path(job_posting), params: {
        provider: "workday",
        url: "#{canonical_url}?wwwr_id=#{job_posting.id}",
        extracted: {
          title: "Principal Software Engineer",
          company: "Cengage",
          location: "United States",
          description_text: "Principal posting body",
          canonical_url: canonical_url
        }
      }

      expect(response).to be_successful
      expect(job_posting.reload.target_url).to eq(canonical_url)
    end
  end

    it "merges known jsonb fields into the existing data column without clobbering it" do
      job_posting.update!(data: { "existing_key" => "kept" })

      post enrich_api_job_posting_path(job_posting), params: {
        provider: "linkedin",
        extracted: { description_text: "Description.", salary_min: "100000", remote: "true" }
      }

      data = job_posting.reload.data
      expect(data["existing_key"]).to eq("kept")
      expect(data["salary_min"]).to eq("100000")
      expect(data["remote"]).to eq("true")
    end

    it "detects the provider from the URL when no provider param is sent" do
      html = "<html><body><div id=\"jobDescriptionText\">From Indeed.</div></body></html>"

      post enrich_api_job_posting_path(job_posting), params: {
        url: "https://www.indeed.com/viewjob?jk=abc", html: html
      }

      expect(response).to be_successful
    end

    it "returns 404 json for a missing job posting" do
      post enrich_api_job_posting_path(id: 0), params: { extracted: { description_text: "x" } }

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["success"]).to be false
    end
  end
end
