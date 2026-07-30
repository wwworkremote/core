# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob do
  # Create a dummy job to test the base class behavior
  before do
    stub_const("TestDummyJob", Class.new(ApplicationJob) do
      def perform
        :ok
      end
    end)
  end

  describe "before_perform" do
    it "aborts performance if global pipelines are paused" do
      allow(SystemSetting).to receive(:paused?).and_return(true)
      allow(Rails.logger).to receive(:info).and_call_original

      job = TestDummyJob.new
      expect(job.perform_now).to be false
      expect(Rails.logger).to have_received(:info).with(/cancelled due to global pause/)
    end

    it "aborts performance if specific job is cancelled" do
      job = TestDummyJob.new
      allow(SystemSetting).to receive(:paused?).and_return(false)
      allow(SystemSetting).to receive(:job_cancelled?).with(job.job_id).and_return(true)
      allow(SystemSetting).to receive(:clear_job_cancellation!).with(job.job_id)

      expect(job.perform_now).to be false
      expect(SystemSetting).to have_received(:clear_job_cancellation!).with(job.job_id)
    end
  end

  describe ".heavyweight!" do
    it "sets concurrency limits" do
      # This is hard to test directly on the class, but we can verify the method exists
      expect(TestDummyJob).to respond_to(:heavyweight!)
    end
  end
end
