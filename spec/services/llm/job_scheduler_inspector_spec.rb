# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::JobSchedulerInspector do
  let(:config_path) { described_class::CONFIG_PATH }
  let(:mock_yaml) do
    {
      "development" => {
        "nightly_database_backup" => { "class" => "DatabaseBackupJob", "schedule" => "daily" },
        "fetch_all_jobs" => { "class" => "DataAcquisition::RunAllJob", "schedule" => "every 6h" }
      }
    }
  end

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(config_path).and_return(true)
    allow(YAML).to receive(:load_file).with(config_path).and_return(mock_yaml)
  end

  describe ".call" do
    it "categorizes and returns task info" do
      result = described_class.call

      expect(result[:utilities].first[:id]).to eq("nightly_database_backup")
      expect(result[:pipeline].first[:id]).to eq("fetch_all_jobs")
      expect(result[:pipeline].first[:class_name]).to eq("DataAcquisition::RunAllJob")
    end
  end
end
