# frozen_string_literal: true

class Admin::TasksController < ApplicationController
  def index
    @tasks = user_tasks
    @pending_tasks = @tasks.where(status: "pending")
    @in_progress_tasks = @tasks.where(status: "in_progress")
    @completed_tasks = @tasks.where(status: "completed").limit(10)
  end

  def create
    @job_posting = JobPosting.find(params.expect(:job_posting_id))
    @task = build_task(@job_posting)

    redirect_after_save(@task.save, target: @job_posting, success: "🎯 Mission Control: Task registered.",
                                    failure: "Failed to register task.")
  end

  def update
    @task = InterviewTask.find(params.expect(:id))

    redirect_after_save(@task.update(task_params), target: admin_tasks_path, success: "Task updated.",
                                                   failure: "Update failed.")
  end

  private

  def user_tasks
    InterviewTask.where(user: current_user).order(due_at: :asc).includes(:job_posting)
  end

  def build_task(job_posting)
    task = job_posting.interview_tasks.build(task_params)
    task.user = current_user
    task.status ||= "pending"
    task
  end

  def redirect_after_save(saved, target:, success:, failure:)
    saved ? redirect_back_or_to(target, notice: success) : redirect_back_or_to(target, alert: failure)
  end

  def task_params
    params.permit(:title, :description, :due_at, :status, artifacts: [])
  end
end
