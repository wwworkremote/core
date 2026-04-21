# frozen_string_literal: true

module Admin
  class JobsController < Admin::ApplicationController
    def index
      @scheduled_count = SolidQueue::ScheduledExecution.count
      @ready_count = SolidQueue::ReadyExecution.count
      @blocked_count = SolidQueue::BlockedExecution.count
      @failed_count = SolidQueue::FailedExecution.count
      
      # Recurring Tasks & Schedules
      @recurring_tasks = SolidQueue::RecurringTask.all
      @last_runs = calculate_last_runs

      # Golden Signals
      @latency = calculate_latency
      @throughput = calculate_throughput # jobs per minute (last hour)
      @error_rate = calculate_error_rate # % of failed vs total finished (last hour)
      @active_processes = SolidQueue::Process.all.order(last_heartbeat_at: :desc)
      @saturation = (@ready_count.to_f / (@active_processes.where(kind: "Worker").sum { |p| p.metadata["thread_pool_size"] || 0 }.to_f + 0.1) * 100).round(1)
      
      @stalled_jobs = @last_runs.select { |_, last_run| last_run < 24.hours.ago }

      # Grouping jobs by queue
      @queues = SolidQueue::Job.where(finished_at: nil).group(:queue_name).count
      
      # Fetching failed jobs with error details
      @failed_jobs = SolidQueue::Job.joins(:failed_execution)
                                    .order(created_at: :desc)
                                    .limit(50)

      @recent_jobs = SolidQueue::Job.order(created_at: :desc).limit(50)
    end

    private

    def calculate_latency
      oldest_ready = SolidQueue::ReadyExecution.order(created_at: :asc).first
      return 0 unless oldest_ready
      (Time.current - oldest_ready.created_at).round(1)
    end

    def calculate_throughput
      finished_last_hour = SolidQueue::Job.where(finished_at: 1.hour.ago..).count
      (finished_last_hour / 60.0).round(2)
    end

    def calculate_error_rate
      last_hour = SolidQueue::Job.where(finished_at: 1.hour.ago..)
      total = last_hour.count
      return 0 if total.zero?
      
      failed = last_hour.joins(:failed_execution).count
      ((failed.to_f / total) * 100).round(1)
    end

    def calculate_last_runs
      # Get the last finished_at for every job class seen in the last 7 days
      SolidQueue::Job.where(finished_at: 7.days.ago..)
                     .group(:class_name)
                     .maximum(:finished_at)
    end
  end
end
