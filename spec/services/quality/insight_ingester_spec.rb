# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quality::InsightIngester do
  describe ".ingest_brakeman" do
    let(:json) do
      {
        warnings: [{
          confidence: "High",
          message: "Possible SQL injection",
          file: "app/models/user.rb",
          line: 10,
          code: "User.where(params[:id])"
        }]
      }.to_json
    end

    it "creates SystemInsight records from Brakeman JSON" do
      expect {
        described_class.ingest_brakeman(json)
      }.to change(SystemInsight, :count).by(1)

      insight = SystemInsight.last
      expect(insight.tool).to eq("brakeman")
      expect(insight.severity).to eq("critical")
      expect(insight.active).to be true
    end
  end

  describe ".ingest_rubocop" do
    let(:json) do
      {
        files: [{
          path: "app/models/user.rb",
          offenses: [{
            severity: "warning",
            cop_name: "Style/Quotes",
            message: "Prefer double quotes",
            location: { line: 5 }
          }]
        }]
      }.to_json
    end

    it "creates SystemInsight records from Rubocop JSON" do
      expect {
        described_class.ingest_rubocop(json)
      }.to change(SystemInsight, :count).by(1)

      insight = SystemInsight.last
      expect(insight.tool).to eq("rubocop")
      expect(insight.message).to include("Style/Quotes")
    end
  end
end
