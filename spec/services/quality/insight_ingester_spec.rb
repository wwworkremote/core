# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quality::InsightIngester do
  describe ".ingest_rubocop" do
    let(:json_report) do
      {
        files: [
          {
            path: "app/models/user.rb",
            offenses: [
              {
                severity: "warning",
                message: "Style/StringLiterals: Prefer single-quoted strings...",
                cop_name: "Style/StringLiterals",
                location: { line: 10 }
              }
            ]
          }
        ]
      }.to_json
    end

    it "creates SystemInsight records" do
      expect {
        described_class.ingest_rubocop(json_report)
      }.to change(SystemInsight, :count).by(1)

      insight = SystemInsight.last
      expect(insight.tool).to eq("rubocop")
      expect(insight.file_path).to eq("app/models/user.rb")
      expect(insight.severity).to eq("warning")
    end

    it "marks old insights as inactive" do
      SystemInsight.create!(tool: :rubocop, message: "Old", file_path: "app/models/user.rb", active: true)

      described_class.ingest_rubocop(json_report)

      expect(SystemInsight.where(message: "Old").first.active).to be false
    end
  end
end
