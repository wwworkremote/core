# frozen_string_literal: true

require "rails_helper"

# Covers TASK-104's acceptance criteria for the sandbox provider --
# docs/architecture/sandbox-provider.md.
RSpec.describe "Sandbox provider" do
  describe "GET /sandbox/postings/:id" do
    it "renders the fake Greenhouse-shaped posting with job_post_id present from page load" do
      get sandbox_posting_path(1)

      expect(response).to be_successful
      expect(response.body).to include('id="application-form"')
      expect(response.body).to match(/data-job-post-id="[a-f0-9]+"/)
      expect(response.body).not_to include("ats_application_id")
    end

    # Selectors TASK-78's real extension listener already targets on a real
    # Greenhouse #application-form -- see extension/content.js.
    it "mirrors the field ids/classes the extension listener targets" do
      get sandbox_posting_path(1)

      expect(response.body).to include('id="question_1"')
      expect(response.body).to include('id="question_1-label"')
      expect(response.body).to include('id="demographic-section"')
    end
  end

  describe "POST /sandbox/applications" do
    it "mints ats_application_id only at confirmation, not before" do
      post sandbox_applications_path, params: { job_post_id: "abc123" }

      expect(response).to be_successful
      expect(response.body).to match(/data-ats-application-id="[a-f0-9]+"/)
      expect(response.body).to include("abc123")
    end
  end

  describe "environment gate" do
    it "does not exist as a route outside development/test" do
      original_env = Rails.env
      begin
        Rails.env = "production"
        Rails.application.reload_routes!

        expect { Rails.application.routes.recognize_path("/sandbox/postings/1") }
          .to raise_error(ActionController::RoutingError)
      ensure
        Rails.env = original_env
        Rails.application.reload_routes!
      end
    end
  end
end
