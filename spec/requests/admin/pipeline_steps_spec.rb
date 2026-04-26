# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::PipelineSteps", type: :request do
  let!(:job) { create(:job_posting) }

  describe "POST /admin/job_postings/:job_posting_id/pipeline_steps" do
    it "changes the job status using an event" do
      post admin_job_posting_pipeline_steps_path(job), params: { status: "favorite" }
      
      expect(response).to redirect_to(admin_job_posting_path(job))
      job.reload
      expect(job.status).to eq("favorited")
      expect(job.pipeline_steps.count).to eq(1)
    end

    it "adds an activity note" do
      expect {
        post admin_job_posting_pipeline_steps_path(job), params: { note: "Discussed with recruiter" }
      }.to change(job.pipeline_steps, :count).by(1)

      expect(response).to redirect_to(admin_job_posting_path(job))
      expect(job.pipeline_steps.last.note).to eq("Discussed with recruiter")
    end
  end
end
