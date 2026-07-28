# frozen_string_literal: true

# Computes every stat Admin::JobsController#index needs -- split out to
# keep the controller itself under Metrics/ClassLength. Exposes one
# attr_reader per value the view (app/views/admin/jobs/index.html.erb)
# expects as an instance variable, so the controller just assigns
# @foo = dashboard.foo for each and the view needs no changes.
class Admin::JobsController::Dashboard
  attr_reader :scheduled_count, :ready_count, :blocked_count, :failed_count,
              :scheduler_info, :recurring_tasks, :last_runs,
              :latency, :throughput, :error_rate, :active_processes, :saturation,
              :throughput_per_min, :eta_minutes, :stalled_jobs, :running_too_long, :queues,
              :failed_jobs, :recent_jobs

  def self.call
    new.call
  end

  # 5 named steps + explicit self (needed since the last assign_* method's
  # own return value isn't this object) -- already the decomposed form;
  # rubocop:disable Metrics/MethodLength
  def call
    assign_queue_counts
    assign_scheduler_info
    assign_golden_signals
    assign_queue_depletion_stats
    assign_job_lists
    self
  end
  # rubocop:enable Metrics/MethodLength

  private

  def assign_queue_counts
    @scheduled_count = SolidQueue::ScheduledExecution.count
    @ready_count = SolidQueue::ReadyExecution.count
    @blocked_count = SolidQueue::BlockedExecution.count
    @failed_count = SolidQueue::FailedExecution.count
  end

  # Correlate YAML schedule with actual executions
  def assign_scheduler_info
    @scheduler_info = ::LLM::JobSchedulerInspector.call
    @recurring_tasks = SolidQueue::RecurringTask.all
    @last_runs = calculate_last_runs
  end

  def assign_golden_signals
    @latency = calculate_latency
    @throughput = calculate_throughput # jobs per minute (last hour)
    @error_rate = calculate_error_rate # % of failed vs total finished (last hour)
    @active_processes = SolidQueue::Process.order(last_heartbeat_at: :desc)
    @saturation = calculate_saturation
  end

  def calculate_saturation
    (@ready_count.to_f / (total_worker_threads.to_f + 0.1) * 100).round(1)
  end

  def total_worker_threads
    @active_processes.where(kind: "Worker").sum { |p| p.metadata["thread_pool_size"] || 0 }
  end

  def assign_queue_depletion_stats
    @throughput_per_min = calculate_throughput # jobs per minute
    @eta_minutes = calculate_eta_minutes
    @stalled_jobs = @last_runs.select { |_, last_run| last_run < 24.hours.ago }
    @running_too_long = stalled_claimed_executions
    @queues = unfinished_jobs_by_queue
  end

  def unfinished_jobs_by_queue
    SolidQueue::Job.where(finished_at: nil).group(:queue_name).count
  end

  def calculate_eta_minutes
    return nil unless @throughput_per_min.positive?

    (@ready_count / @throughput_per_min).round(1)
  end

  # Claimed but running too long (e.g. > 30 mins)
  def stalled_claimed_executions
    SolidQueue::ClaimedExecution.where(created_at: ..30.minutes.ago)
                                .includes(:job)
                                .order(created_at: :asc)
  end

  def assign_job_lists
    @failed_jobs = SolidQueue::Job.joins(:failed_execution)
                                  .order(created_at: :desc)
                                  .limit(50)
    @recent_jobs = SolidQueue::Job.order(created_at: :desc).limit(50)
  end

  def calculate_latency
    oldest_ready = SolidQueue::ReadyExecution.order(created_at: :asc).first
    return 0 unless oldest_ready

    (Time.current - oldest_ready.created_at).round(1)
  end

  def calculate_throughput
    finished_last_5_min = SolidQueue::Job.where(finished_at: 5.minutes.ago..).count
    (finished_last_5_min / 5.0).round(2)
  end

  def calculate_error_rate
    scope = finished_last_hour
    total = scope.count
    return 0 if total.zero?

    ((scope.joins(:failed_execution).count.to_f / total) * 100).round(1)
  end

  def finished_last_hour
    SolidQueue::Job.where(finished_at: 1.hour.ago..)
  end

  # Get the last finished_at for every job class seen in the last 7 days
  def calculate_last_runs
    SolidQueue::Job.where(finished_at: 7.days.ago..)
                   .group(:class_name)
                   .maximum(:finished_at)
  end
end
