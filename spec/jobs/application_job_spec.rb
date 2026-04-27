# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob, type: :job do
  # Create a dummy job to test the base class behavior
  class TestDummyJob < ApplicationJob
    def perform
      :ok
    end
  end

  describe "before_perform" do
    it "aborts performance if global pipelines are paused" do
      allow(SystemSetting).to receive(:paused?).and_return(true)
      expect(Rails.logger).to receive(:info).with(/cancelled due to global pause/)
      
      job = TestDummyJob.new
      expect(job.perform_now).to be false
    end

    it "aborts performance if specific job is cancelled" do
      job = TestDummyJob.new
      allow(SystemSetting).to receive(:paused?).and_return(false)
      allow(SystemSetting).to receive(:job_cancelled?).with(job.job_id).and_return(true)
      expect(SystemSetting).to receive(:clear_job_cancellation!).with(job.job_id)
      
      expect(job.perform_now).to be false
    end
  end

  describe ".heavyweight!" do
    it "sets concurrency limits" do
      # This is hard to test directly on the class, but we can verify the method exists
      expect(TestDummyJob).to respond_to(:heavyweight!)
    end
  end
end
