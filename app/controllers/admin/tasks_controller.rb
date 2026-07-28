# frozen_string_literal: true

class Admin::TasksController < ApplicationController
  def index
    @tasks = InterviewTask.where(user: current_user)
                          .order(due_at: :asc)
                          .includes(:job_posting)

    @pending_tasks = @tasks.where(status: "pending")
    @in_progress_tasks = @tasks.where(status: "in_progress")
    @completed_tasks = @tasks.where(status: "completed").limit(10)
  end

  def create
    @job_posting = JobPosting.find(params.expect(:job_posting_id))
    @task = @job_posting.interview_tasks.build(task_params)
    @task.user = current_user
    @task.status ||= "pending"

    if @task.save
      redirect_back_or_to(@job_posting, notice: "🎯 Mission Control: Task registered.")
    else
      redirect_back_or_to(@job_posting, alert: "Failed to register task.")
    end
  end

  def update
    @task = InterviewTask.find(params.expect(:id))
    if @task.update(task_params)
      redirect_back_or_to(admin_tasks_path, notice: "Task updated.")
    else
      redirect_back_or_to(admin_tasks_path, alert: "Update failed.")
    end
  end


  private

  def task_params
    params.permit(:title, :description, :due_at, :status, artifacts: [])
  end
end
