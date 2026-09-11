# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Tasks" do
  let(:user) { create(:user) }
  let!(:job) { create(:job_posting) }

  describe "GET /admin/tasks" do
    it "returns a success response" do
      get admin_tasks_path
      expect(response).to be_successful
    end
  end

  describe "POST /admin/tasks" do
    let(:task_params) do
      {
        job_posting_id: job.id,
        title: "Prepare for Interview",
        status: "pending"
      }
    end

    it "creates a new task and redirects" do
      expect {
        post admin_tasks_path, params: task_params
      }.to change(InterviewTask, :count).by(1)

      expect(response).to redirect_to(job_posting_path(job))
    end

    it "redirects with an alert when the task is invalid" do
      expect {
        post admin_tasks_path, params: task_params.merge(title: "")
      }.not_to change(InterviewTask, :count)

      expect(response).to redirect_to(job_posting_path(job))
      expect(flash[:alert]).to eq("Failed to register task.")
    end
  end

  describe "PATCH /admin/tasks/:id" do
    let!(:task) { create(:interview_task, user: user, job_posting: job) }

    it "updates the task status and redirects" do
      patch admin_task_path(task), params: { status: "completed" }
      expect(response).to redirect_to(admin_tasks_path)
      task.reload
      expect(task.status).to eq("completed")
    end

    it "redirects with an alert when the update is invalid" do
      patch admin_task_path(task), params: { title: "" }
      expect(response).to redirect_to(admin_tasks_path)
      expect(flash[:alert]).to eq("Update failed.")
    end
  end
end
