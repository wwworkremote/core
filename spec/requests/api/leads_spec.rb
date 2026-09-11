# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Leads" do
  describe "POST /api/leads" do
    it "captures a new lead" do
      post api_leads_path, as: :json, params: {
        url: "https://www.dice.com/job-detail/abc123",
        provider: "dice", title: "Senior Engineer", company_name: "Acme",
        location: "Remote", raw_html: "<html></html>",
        discovery: { extraction_confidence: "high", extraction_method: "json_ld", field_count: 9 }
      }

      expect(response).to have_http_status(:created)
      assert_schema_conform(201)
      expect(response.parsed_body["success"]).to be true
      expect(Lead.find(response.parsed_body["id"]).status).to eq("captured")
    end

    it "tracks a Captured Lead Ahoy event with extraction quality metadata" do
      # Ahoy skips tracking for requests it detects as bots (no real
      # User-Agent, as an unconfigured RSpec request-spec sends) -- the
      # extension's actual fetch() always carries a genuine Chrome UA, so
      # match that here rather than loosening bot detection itself.
      chrome_ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
                  "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

      expect do
        post api_leads_path, as: :json, headers: { "User-Agent" => chrome_ua }, params: {
          url: "https://www.dice.com/job-detail/abc123", provider: "dice",
          discovery: { extraction_confidence: "high", extraction_method: "json_ld", field_count: 9 }
        }
      end.to change(Ahoy::Event, :count).by(1)

      event = Ahoy::Event.last
      expect(event.name).to eq("Captured Lead")
      expect(event.properties).to include(
        "provider" => "dice", "extraction_method" => "json_ld",
        "extraction_confidence" => "high", "field_count" => 9
      )
    end

    it "refreshes found_at instead of duplicating on a revisit" do
      url = "https://www.dice.com/job-detail/abc123"
      post api_leads_path, as: :json, params: { url: url, provider: "dice" }
      first_id = response.parsed_body["id"]

      post api_leads_path, as: :json, params: { url: url, provider: "dice" }

      expect(response.parsed_body["id"]).to eq(first_id)
      expect(Lead.where(url: url).count).to eq(1)
    end
  end

  describe "POST /api/leads/:id/promote" do
    let!(:lead) { create(:lead) }

    before do
      allow(JobBoards::Categorizer).to receive(:new).and_return(instance_double(JobBoards::Categorizer, call: true))
      allow(JobBoards::Embedder).to receive(:new).and_return(instance_double(JobBoards::Embedder, call: true))
    end

    it "promotes the lead into a new JobPosting" do
      post promote_api_lead_path(lead), as: :json, params: {
        title: "Senior Engineer", location: "Remote",
        target_url: "https://www.dice.com/job-detail/abc123",
        body: "Full description text.", company: { name: "Acme Corp" },
        data: { employment_type: "FULL_TIME" }
      }

      expect(response).to have_http_status(:ok)
      assert_schema_conform(200)
      body = response.parsed_body
      expect(body["success"]).to be true
      expect(body["lead_id"]).to eq(lead.id)
      expect(JobPosting.find(body["job_posting_id"]).title).to eq("Senior Engineer")
    end
  end
end
