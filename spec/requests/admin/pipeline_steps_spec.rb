# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::PipelineSteps" do
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

    context "when remove_card is set (the job_postings index ignore button)" do
      it "ignores the posting and responds with a turbo_stream removing its card, not a hard redirect" do
        post admin_job_posting_pipeline_steps_path(job), params: { status: "ignore", remove_card: true },
                                                         as: :turbo_stream

        expect(job.reload.status).to eq("ignored")
        expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
        expect(response.body).to include("remove")
        expect(response.body).to include(ActionView::RecordIdentifier.dom_id(job))
      end
    end

    context "when the request accepts turbo_stream but remove_card is not set (every other status button)" do
      # Turbo Drive sends `Accept: text/vnd.turbo-stream.html` on every form
      # submission by default -- this is the regression case: a naive
      # `respond_to { |format| format.turbo_stream { ... } }` on this shared
      # action would hijack Favorite/Apply/etc. too, not just the index's
      # dedicated ignore button. Every other caller (job_postings/show,
      # admin/job_postings/show, admin/companies/show) still expects the
      # plain redirect + flash notice regardless of what the browser's Accept
      # header offers.
      it "still redirects with a flash notice for a plain status change" do
        post admin_job_posting_pipeline_steps_path(job), params: { status: "favorite" }, as: :turbo_stream

        expect(job.reload.status).to eq("favorited")
        expect(response).to redirect_to(admin_job_posting_path(job))
        follow_redirect!
        expect(response.body).to include("Activity logged")
      end
    end
  end
end
