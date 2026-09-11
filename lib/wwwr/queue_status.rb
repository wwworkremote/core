# frozen_string_literal: true

# Queue-depth-by-class and oldest-unclaimed-job for bin/wwwr status -- the
# exact numbers that took a dozen hand-written bin/rails runner one-liners
# to derive during the 2026-08-17 dead-worker incident.
class Wwwr::QueueStatus
  TOP_N = 5

  def self.call
    new.call
  end

  def call
    [summary_line, oldest_line, *top_classes_lines].join("\n")
  end

  private

  def unclaimed
    SolidQueue::Job.where(finished_at: nil)
                   .joins("LEFT JOIN solid_queue_claimed_executions sqce ON sqce.job_id = solid_queue_jobs.id")
                   .where(sqce: { id: nil })
  end

  def summary_line
    "Unclaimed pending jobs: #{unclaimed.count}"
  end

  def oldest_line
    oldest = unclaimed.order(:created_at).first
    return "Oldest unclaimed:       none" unless oldest

    "Oldest unclaimed:       #{oldest.class_name} (#{age_minutes(oldest)}m old, queue=#{oldest.queue_name})"
  end

  def age_minutes(job)
    ((Time.current - job.created_at) / 60).round
  end

  def top_classes_lines
    unclaimed.group(:class_name).order(Arel.sql("count_all DESC")).limit(TOP_N).count
             .map { |klass, n| "  #{n}\t#{klass}" }
  end
end
