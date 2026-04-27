# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::PipelineSteps", type: :request do
  let!(:job) { create(:job_posting, status: "none") }

  describe "POST /admin/job_postings/:job_posting_id/pipeline_steps" do
    it "logs a status change" do
      expect {
        post admin_job_posting_pipeline_steps_path(job), params: { status: "favorite" }
      }.to change(PipelineStep, :count).by(1)
      
      expect(response).to redirect_to(admin_job_posting_path(job))
      expect(job.reload.status).to eq("favorited")
    end

    it "logs a research note" do
      expect {
        post admin_job_posting_pipeline_steps_path(job), params: { note: "Interviewing tomorrow" }
      }.to change(PipelineStep, :count).by(1)
      
      step = PipelineStep.last
      expect(step.note).to eq("Interviewing tomorrow")
    end
  end
end
