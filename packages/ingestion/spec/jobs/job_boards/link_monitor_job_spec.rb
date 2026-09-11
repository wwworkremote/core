# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::LinkMonitorJob do
  let(:job_posting) { create(:job_posting, target_url: "https://example.com/jobs/1") }

  describe "#perform" do
    it "archives a job whose link returns 404" do
      job_posting
      stub_request(:head, "https://example.com/jobs/1").to_return(status: 404)

      described_class.perform_now

      expect(job_posting.reload.status).to eq("archived")
      expect(job_posting.pipeline_steps.last.note).to include("Link returned 404")
    end

    it "archives a job whose redirect leads to an expired-posting page" do
      job_posting
      stub_request(:head, "https://example.com/jobs/1")
        .to_return(status: 301, headers: { "location" => "https://example.com/expired" })
      stub_request(:get, "https://example.com/expired")
        .to_return(status: 200, body: "This job is no longer available.")

      described_class.perform_now

      expect(job_posting.reload.status).to eq("archived")
      expect(job_posting.pipeline_steps.last.note).to include("Redirect signal")
    end

    it "does not archive when the redirect target is a normal page" do
      job_posting
      stub_request(:head, "https://example.com/jobs/1")
        .to_return(status: 301, headers: { "location" => "https://example.com/still-open" })
      stub_request(:get, "https://example.com/still-open").to_return(status: 200, body: "Apply now!")

      described_class.perform_now

      expect(job_posting.reload.status).to eq("none")
    end

    it "does not archive a job that responds successfully" do
      job_posting
      stub_request(:head, "https://example.com/jobs/1").to_return(status: 200)

      described_class.perform_now

      expect(job_posting.reload.status).to eq("none")
    end

    it "logs and continues when the connection fails" do
      job_posting
      stub_request(:head, "https://example.com/jobs/1").to_raise(Faraday::ConnectionFailed.new("timeout"))
      allow(Rails.logger).to receive(:warn)

      described_class.perform_now

      expect(job_posting.reload.status).to eq("none")
      expect(Rails.logger).to have_received(:warn).with(/Connection failed/)
    end

    it "only checks non-archived jobs with a present target_url" do
      archived = create(:job_posting, target_url: "https://example.com/archived", status: "archived")
      blank_url = create(:job_posting, target_url: "", signature: SecureRandom.hex(16))
      stub_request(:head, "https://example.com/jobs/1").to_return(status: 200)

      described_class.perform_now

      expect(WebMock).not_to have_requested(:head, "https://example.com/archived")
      expect(archived.reload.status).to eq("archived")
      expect(blank_url.reload.status).to eq("none")
    end
  end
end
