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

    it "deactivates prior brakeman insights for files mentioned in the report" do
      stale = SystemInsight.create!(tool: :brakeman, severity: :warning, message: "stale",
                                    file_path: "app/models/user.rb", active: true)

      described_class.ingest_brakeman(json)

      expect(stale.reload.active).to be false
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

    it "deactivates prior rubocop insights for files mentioned in the report" do
      stale = SystemInsight.create!(tool: :rubocop, severity: :warning, message: "stale",
                                    file_path: "app/models/user.rb", active: true)

      described_class.ingest_rubocop(json)

      expect(stale.reload.active).to be false
    end
  end

  describe ".ingest_reek" do
    let(:json) do
      [
        {
          "context" => "User",
          "lines" => [3, 7],
          "message" => "has no descriptive comment",
          "smell_type" => "IrresponsibleModule",
          "source" => "app/models/user.rb"
        }
      ].to_json
    end

    it "creates one SystemInsight per reported line" do
      expect {
        described_class.ingest_reek(json)
      }.to change(SystemInsight, :count).by(2)

      insight = SystemInsight.order(:line_number).first
      expect(insight.tool).to eq("reek")
      expect(insight.severity).to eq("warning")
      expect(insight.message).to include("IrresponsibleModule")
      expect(insight.file_path).to eq("app/models/user.rb")
      expect(insight.line_number).to eq(3)
    end
  end
end
