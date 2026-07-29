# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CareerProfiles" do
  let(:user) do
    User.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")) do |u|
      u.name = ENV.fetch("ADMIN_NAME", "mike")
      u.password = ENV.fetch("ADMIN_PASSWORD", "password")
    end
  end
  let!(:career_profile) { user.career_profile || user.create_career_profile! }

  before { ActiveJob::Base.queue_adapter = :test }

  describe "GET /career_profile" do
    it "shows the current user's career profile" do
      get career_profile_path
      expect(response).to be_successful
    end
  end

  describe "PATCH /career_profile" do
    it "syncs from the resume YAML source and enqueues embedding when sync is requested" do
      allow(Resume::YamlImporter).to receive(:call)

      patch career_profile_path, params: { sync: "true" }

      expect(Resume::YamlImporter).to have_received(:call).with(user)
      expect(response).to redirect_to(career_profile_path)
      expect(flash[:notice]).to include("synchronization initiated")
    end

    it "enqueues embedding only when embed is requested" do
      expect {
        patch career_profile_path, params: { embed: "true" }
      }.to have_enqueued_job(Resume::EmbeddingJob).with(career_profile.id)

      expect(flash[:notice]).to include("Neural vector synthesis initiated")
    end

    it "updates attributes and enqueues embedding on a normal save" do
      patch career_profile_path, params: { career_profile: { goals: "Ship great software" } }

      expect(career_profile.reload.goals).to eq("Ship great software")
      expect(flash[:notice]).to include("updated and synthesis initiated")
    end

    it "re-renders edit on validation failure" do
      patch career_profile_path, params: { career_profile: { github_url: "not-a-url" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /career_profile/sync_github" do
    it "sets a success notice when GithubProcessor succeeds" do
      allow(LLM::GithubProcessor).to receive(:call).and_return(success: true)

      post sync_github_career_profile_path

      expect(response).to redirect_to(career_profile_path)
      expect(flash[:notice]).to include("synchronized successfully")
    end

    it "sets an alert when GithubProcessor fails" do
      allow(LLM::GithubProcessor).to receive(:call).and_return(success: false, error: "rate limited")

      post sync_github_career_profile_path

      expect(flash[:alert]).to include("rate limited")
    end
  end
end
