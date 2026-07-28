# frozen_string_literal: true

# clear_solid_queue_finished_jobs (config/recurring.yml) only clears *finished*
# jobs -- nothing prunes stale still-pending or long-failed ones. That's how a
# 5,427-row / 166-failure backlog accumulated silently over ~3 months before
# manual cleanup on 2026-07-27 (TASK-19, TASK-21, TASK-25). A job that's still
# unprocessed or unfixed after RETENTION has, in practice, already needed
# manual intervention -- eternal DB retention isn't serving as anyone's audit
# trail, it's just silent accumulation waiting to be rediscovered the hard way.
class SolidQueueMaintenance::StaleJobPruner
  RETENTION = 30.days

  def self.call(retention: RETENTION)
    new(retention).call
  end

  def initialize(retention)
    @cutoff = retention.ago
  end

  def call
    { discarded_pending: discard_stale_pending, discarded_failed: discard_stale_failed }
  end

  private

  def discard_stale_pending
    jobs = SolidQueue::Job.where(finished_at: nil).where(created_at: ...@cutoff).to_a
    jobs.each(&:discard)
    jobs.size
  end

  def discard_stale_failed
    failures = SolidQueue::FailedExecution.where(created_at: ...@cutoff).to_a
    failures.each(&:discard)
    failures.size
  end
end
