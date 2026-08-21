# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::ApplicationStatus" do
  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting) }

  # The controller resolves the actor as User.first (this is a single-user
  # system, same as Api::V0::ProfileController). Stub it rather than assuming
  # the factory user sorts first -- any stray row in the shared test DB would
  # otherwise silently point the request at a different user.
  before { allow(User).to receive(:first).and_return(user) }

  describe "GET show" do
    it "reports none with the events available to an untracked posting" do
      get "/api/v0/job_postings/#{job_posting.id}/application_status"

      expect(response.parsed_body).to include("status" => "none", "available_events" => %w[favorite apply])
    end

    it "reports the current status once the posting is tracked" do
      create(:user_job_posting, user: user, job_posting: job_posting, status: "applied")

      get "/api/v0/job_postings/#{job_posting.id}/application_status"

      expect(response.parsed_body["status"]).to eq("applied")
    end
  end

  describe "POST create" do
    it "marks a previously untracked posting as applied" do
      post "/api/v0/job_postings/#{job_posting.id}/application_status", params: { event: "apply" }

      expect(response.parsed_body).to include("success" => true, "status" => "applied")
    end

    it "logs a pipeline step so the timeline matches a web-UI transition" do
      expect do
        post "/api/v0/job_postings/#{job_posting.id}/application_status", params: { event: "apply" }
      end.to change(PipelineStep, :count).by(1)
    end

    it "reports failure instead of raising when the transition is illegal" do
      create(:user_job_posting, user: user, job_posting: job_posting, status: "archived")

      post "/api/v0/job_postings/#{job_posting.id}/application_status", params: { event: "apply" }

      expect(response.parsed_body).to include("success" => false, "status" => "archived")
    end

    it "refuses an event that is not a known transition" do
      post "/api/v0/job_postings/#{job_posting.id}/application_status", params: { event: "delete_everything" }

      expect(response.parsed_body).to include("success" => false, "status" => "none")
    end
  end
end
