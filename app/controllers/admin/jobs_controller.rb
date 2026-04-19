# frozen_string_literal: true

module Admin
  class JobsController < Admin::ApplicationController
    def index
      @scheduled_count = SolidQueue::ScheduledExecution.count
      @ready_count = SolidQueue::ReadyExecution.count
      @blocked_count = SolidQueue::BlockedExecution.count
      @failed_count = SolidQueue::FailedExecution.count
      
      # Grouping jobs by queue to replicate mc-jobs 'Queues' tab
      @queues = SolidQueue::Job.where(finished_at: nil).group(:queue_name).count
      
      # Fetching failed jobs with error details
      @failed_jobs = SolidQueue::Job.joins(:failed_execution)
                                    .order(created_at: :desc)
                                    .limit(50)

      @recent_jobs = SolidQueue::Job.order(created_at: :desc).limit(50)
    end
  end
end
