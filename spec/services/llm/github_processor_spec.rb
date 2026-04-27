# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::GithubProcessor do
  let(:career_profile) { create(:career_profile, github_url: "https://github.com/testuser") }
  let(:processor) { described_class.new(career_profile) }

  describe "#call" do
    before do
      # 1. Stub Repos
      stub_request(:get, "https://api.github.com/users/testuser/repos?per_page=20&sort=updated")
        .to_return(status: 200, body: [{ name: "rails-core", description: "Fixing rails", language: "Ruby" }].to_json, 
                   headers: { "Content-Type" => "application/json" })

      # 2. Stub README
      readme_content = Base64.encode64("# Rails Core Fork\nExpert level stuff.")
      stub_request(:get, "https://api.github.com/repos/testuser/rails-core/readme")
        .to_return(status: 200, body: { content: readme_content }.to_json, 
                   headers: { "Content-Type" => "application/json" })

      # 3. Stub LLM Orchestrator
      allow(LLM::Orchestrator).to receive(:call).and_return({ success: true, output: "Expert Ruby Developer" })
    end

    it "fetches GitHub data and updates profile synthesis" do
      result = processor.call
      expect(result[:success]).to be true
      
      career_profile.reload
      expect(career_profile.github_context["synthesis"]).to eq("Expert Ruby Developer")
      expect(career_profile.github_context["repos"].first["name"]).to eq("rails-core")
    end

    it "handles missing github_url" do
      career_profile.update!(github_url: nil)
      res = described_class.call(career_profile)
      expect(res[:success]).to be false
      expect(res[:error]).to include("No GitHub username")
    end

    it "handles API failures gracefully" do
      stub_request(:get, /api.github.com/).to_return(status: 500)
      
      # It should return Success: true if LLM works even with 0 repos, 
      # or handle it based on implementation. 
      # Current implementation returns success if synthesis exists.
      result = processor.call
      expect(result[:success]).to be true
      expect(career_profile.reload.github_context["repos"]).to be_empty
    end
  end
end
