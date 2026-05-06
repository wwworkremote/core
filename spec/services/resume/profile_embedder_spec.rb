# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resume::ProfileEmbedder do
  let(:user) { create(:user) }
  let(:career_profile) { create(:career_profile, user: user, skills: "Ruby, Rails", experience_level: "Senior") }
  let(:embedder) { described_class.new(career_profile) }
  let(:mock_embedding) { Array.new(3584) { rand } }

  before do
    create(:work_experience, career_profile: career_profile, title: "Dev", company_name: "A")
  end

  describe "#call" do
    it "fetches and saves the embedding via Faraday" do
      stub_request(:post, described_class::API_URL)
        .to_return(
          status: 200,
          body: { data: [{ embedding: mock_embedding }] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = embedder.call
      expect(result).to be true

      career_profile.reload
      expect(career_profile.embedding.size).to eq(3584)
    end

    it "handles API errors gracefully" do
      stub_request(:post, described_class::API_URL)
        .to_return(status: 503, body: "Down")

      expect(Rails.logger).to receive(:error).with(/API Error: 503/)

      result = embedder.call
      expect(result).to be false
    end

    it "skips if disabled via ENV" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:[]).with("ENABLE_EMBEDDINGS").and_return("false")

      expect(Faraday).not_to receive(:post)
      embedder.call
    end
  end
end
