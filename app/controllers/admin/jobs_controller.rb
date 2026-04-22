# frozen_string_literal: true

module Admin
  class JobsController < Admin::ApplicationController
    def index
      @scheduled_count = SolidQueue::ScheduledExecution.count
      @ready_count = SolidQueue::ReadyExecution.count
      @blocked_count = SolidQueue::BlockedExecution.count
      @failed_count = SolidQueue::FailedExecution.count

      # Correlate YAML schedule with actual executions
      @scheduler_info = ::LLM::JobSchedulerInspector.call

      # Recurring Tasks & Schedules
      @recurring_tasks = SolidQueue::RecurringTask.all
      @last_runs = calculate_last_runs

      # Golden Signals
      @latency = calculate_latency
      @throughput = calculate_throughput # jobs per minute (last hour)
      @error_rate = calculate_error_rate # % of failed vs total finished (last hour)
      @active_processes = SolidQueue::Process.all.order(last_heartbeat_at: :desc)
      @saturation = (@ready_count.to_f / (@active_processes.where(kind: "Worker").sum { |p| p.metadata["thread_pool_size"] || 0 }.to_f + 0.1) * 100).round(1)
      
      # Queue Depletion Stats
      @throughput_per_min = calculate_throughput # jobs per minute
      @eta_minutes = @throughput_per_min > 0 ? (@ready_count / @throughput_per_min).round(1) : nil
      @stalled_jobs = @last_runs.select { |_, last_run| last_run < 24.hours.ago }

      # Claimed but running too long (e.g. > 30 mins)
      @running_too_long = SolidQueue::ClaimedExecution.where(created_at: ..30.minutes.ago)
                                                     .includes(:job)
                                                     .order(created_at: :asc)

      # Grouping jobs by queue
      @queues = SolidQueue::Job.where(finished_at: nil).group(:queue_name).count

      # Fetching failed jobs with error details
      @failed_jobs = SolidQueue::Job.joins(:failed_execution)
                                    .order(created_at: :desc)
                                    .limit(50)

      @recent_jobs = SolidQueue::Job.order(created_at: :desc).limit(50)
    end

    def trigger
      task_id = params[:task_id]
      
      # Whitelist Task IDs to prevent Command Injection and RCE
      all_configs = YAML.load_file(Rails.root.join('config/recurring.yml'))
      allowed_tasks = (all_configs[Rails.env] || all_configs['development']).keys
      
      unless allowed_tasks.include?(task_id)
        flash[:alert] = "Unauthorized or invalid task ID: #{task_id}"
        return redirect_to admin_jobs_path
      end

      env_config = all_configs[Rails.env] || all_configs['development']
      config = env_config[task_id]
      
      if config
        if config['class']
          # Safe because task_id is now whitelisted from recurring.yml
          klass = config['class'].constantize
          args = config['args'] || []
          klass.perform_later(*args)
          flash[:notice] = "🚀 Triggered #{task_id} (#{config['class']})"
        elsif config['command']
          # Safe because command string comes from static recurring.yml, not user input
          spawn("bin/rails runner '#{config['command']}'")
          flash[:notice] = "🚀 Spawned command for #{task_id}"
        end
      else
        flash[:alert] = "Task configuration not found for #{task_id} in #{Rails.env}."
      end
      
      redirect_to admin_jobs_path
    end

    def prune
      count = SolidQueue::Process.prunable.count
      SolidQueue::Process.prunable.each(&:deregister)
      flash[:notice] = "🚀 Pruned #{count} dead processes."
      redirect_to admin_jobs_path
    end

    def details
      @job = SolidQueue::Job.find(params[:id])
      render layout: false
    end

    def discard
      @job = SolidQueue::Job.find(params[:id])
      
      # If the job is claimed (in progress), we need to remove the claim record first
      # to satisfy Solid Queue's integrity checks for discarding.
      SolidQueue::ClaimedExecution.where(job_id: @job.id).destroy_all
      
      @job.discard
      flash[:notice] = "🚀 Job ##{@job.id} terminated and discarded."
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Job not found."
    rescue StandardError => e
      flash[:alert] = "Failed to discard: #{e.message}"
    ensure
      redirect_to admin_jobs_path
    end

    private

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
