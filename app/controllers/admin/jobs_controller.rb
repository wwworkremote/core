# frozen_string_literal: true

module Admin
  class JobsController < Admin::ApplicationController
    def index
      @scheduled_count = SolidQueue::ScheduledExecution.count
      @ready_count = SolidQueue::ReadyExecution.count
      @blocked_count = SolidQueue::BlockedExecution.count
      @failed_count = SolidQueue::FailedExecution.count
      
      @recent_jobs = SolidQueue::Job.order(created_at: :desc).limit(50)
    end
  end
end
