# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolidQueueMaintenance::StaleJobPruner do
  def create_job(created_at:, finished_at: nil)
    SolidQueue::Job.create!(
      active_job_id: SecureRandom.uuid, class_name: "Command", queue_name: "default",
      arguments: "{}", priority: 0, scheduled_at: Time.current,
      created_at: created_at, finished_at: finished_at
    )
  end

  # A real failed job has no ready_execution left, and its FailedExecution
  # row is created well after the job itself -- job_created_at and
  # failure_created_at are kept independent so this can isolate
  # discard_stale_failed's own query from discard_stale_pending's (which
  # would otherwise already sweep up any job old enough to also make its
  # failure stale).
  def create_failed_execution(job_created_at:, failure_created_at:)
    job = create_job(created_at: job_created_at)
    SolidQueue::ReadyExecution.where(job_id: job.id).delete_all
    SolidQueue::FailedExecution.create!(job: job, error: "boom", created_at: failure_created_at)
  end

  describe ".call" do
    it "discards pending jobs older than the retention window" do
      stale = create_job(created_at: 31.days.ago)
      recent = create_job(created_at: 1.day.ago)

      result = described_class.call

      expect(SolidQueue::Job.exists?(stale.id)).to be false
      expect(SolidQueue::Job.exists?(recent.id)).to be true
      expect(result[:discarded_pending]).to eq(1)
    end

    it "does not discard a finished job, even if old" do
      finished = create_job(created_at: 31.days.ago, finished_at: 31.days.ago)

      result = described_class.call

      expect(SolidQueue::Job.exists?(finished.id)).to be true
      expect(result[:discarded_pending]).to eq(0)
    end

    it "discards failed executions older than the retention window" do
      stale = create_failed_execution(job_created_at: 1.day.ago, failure_created_at: 31.days.ago)
      recent = create_failed_execution(job_created_at: 1.day.ago, failure_created_at: 1.day.ago)

      result = described_class.call

      expect(SolidQueue::FailedExecution.exists?(stale.id)).to be false
      expect(SolidQueue::FailedExecution.exists?(recent.id)).to be true
      expect(result[:discarded_failed]).to eq(1)
    end

    it "honors a custom retention window" do
      job = create_job(created_at: 2.days.ago)

      result = described_class.call(retention: 1.day)

      expect(SolidQueue::Job.exists?(job.id)).to be false
      expect(result[:discarded_pending]).to eq(1)
    end
  end
end
