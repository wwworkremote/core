# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Embedder do
  let(:job_posting) { create(:job_posting, title: "Ruby Engineer", body: "We need a Ruby on Rails expert.") }
  let(:embedder) { described_class.new(job_posting) }
  # Must match the job_postings.embedding column width (vector(3584) --
  # see db/schema.rb), not necessarily any particular model's real output
  # size.
  let(:mock_embedding) { Array.new(3584) { rand } }

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

      job_posting.reload
      expect(job_posting.embedding.size).to eq(3584)
    end

    it "handles a 501 (embeddings unsupported on this server) gracefully" do
      stub_request(:post, described_class::API_URL).to_return(status: 501, body: "Not Implemented")
      allow(Rails.logger).to receive(:warn)

      result = embedder.call

      expect(result).to be false
      expect(Rails.logger).to have_received(:warn).with(/does not support embeddings/)
    end

    it "returns false when the response has no embedding" do
      stub_request(:post, described_class::API_URL)
        .to_return(status: 200, body: { data: [] }.to_json, headers: { "Content-Type" => "application/json" })
      allow(Rails.logger).to receive(:error)

      result = embedder.call

      expect(result).to be false
      expect(Rails.logger).to have_received(:error).with(/No embedding found/)
    end

    it "skips blank postings" do
      blank_posting = build(:job_posting, title: "", body: "")
      allow(Faraday).to receive(:post)

      described_class.new(blank_posting).call

      expect(Faraday).not_to have_received(:post)
    end

    it "skips expired postings unless forced" do
      job_posting.expire!
      allow(Faraday).to receive(:post)

      embedder.call

      expect(Faraday).not_to have_received(:post)
    end

    it "skips if disabled via ENV" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:[]).with("ENABLE_EMBEDDINGS").and_return("false")
      allow(Faraday).to receive(:post)

      embedder.call

      expect(Faraday).not_to have_received(:post)
    end
  end
end
