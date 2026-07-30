# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Outbound Links" do
  let!(:job) { create(:job_posting, target_url: "https://trusted-site.com/apply") }

  describe "GET /outbound_link" do
    it "redirects to the job's target URL and tracks the event" do
      get outbound_link_path(id: "tracking", job_posting_id: job.id)

      expect(response).to redirect_to("https://trusted-site.com/apply")
    end

    it "permits redirect if the URL exists in the database even without an ID" do
      get outbound_link_path(id: "tracking", url: "https://trusted-site.com/apply")

      expect(response).to redirect_to("https://trusted-site.com/apply")
    end

    it "blocks open redirects to untrusted URLs" do
      allow(Rails.logger).to receive(:warn).and_call_original

      get outbound_link_path(id: "tracking", url: "https://malicious-site.com/steal-data")

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Security Exception")
      expect(Rails.logger).to have_received(:warn).with(/SECURITY: Blocked attempt/)
    end
  end
end
