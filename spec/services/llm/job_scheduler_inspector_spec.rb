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

  def create_recurring_execution(task_key:, finished_at: nil)
    job = SolidQueue::Job.create!(
      active_job_id: SecureRandom.uuid, class_name: "Command", queue_name: "default",
      arguments: "{}", priority: 0, scheduled_at: Time.current, finished_at: finished_at
    )
    SolidQueue::RecurringExecution.create!(job: job, task_key: task_key, run_at: Time.current)
  end

  describe ".call" do
    it "categorizes and returns task info" do
      result = described_class.call

      expect(result[:utilities].first[:id]).to eq("nightly_database_backup")
      expect(result[:pipeline].first[:id]).to eq("fetch_all_jobs")
      expect(result[:pipeline].first[:class_name]).to eq("DataAcquisition::RunAllJob")
    end

    it "returns an empty array when the config file does not exist" do
      allow(File).to receive(:exist?).with(config_path).and_return(false)

      expect(described_class.call).to eq([])
    end

    it "marks a task as never run when there is no recurring execution" do
      result = described_class.call
      expect(result[:pipeline].first[:status]).to eq("never")
      expect(result[:pipeline].first[:last_run]).to be_nil
    end

    it "marks a task as finished when its last execution's job finished" do
      create_recurring_execution(task_key: "fetch_all_jobs", finished_at: Time.current)

      result = described_class.call

      expect(result[:pipeline].first[:status]).to eq("finished")
      expect(result[:pipeline].first[:last_run]).to be_present
    end

    it "marks a task as running/failed when its last execution's job has not finished" do
      create_recurring_execution(task_key: "fetch_all_jobs", finished_at: nil)

      result = described_class.call

      expect(result[:pipeline].first[:status]).to eq("running/failed")
    end
  end
end
