# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::PipelineSteps" do
  let!(:job) { create(:job_posting, status: "none") }

  describe "POST /admin/job_postings/:job_posting_id/pipeline_steps" do
    it "logs a status change" do
      expect {
        post admin_job_posting_pipeline_steps_path(job), params: { status: "favorite" }
      }.to change(PipelineStep, :count).by(1)

      expect(response).to redirect_to(job_posting_path(job))
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

    context "when marking a posting expired" do
      it "expires the posting, distinct from ignore/not-interested" do
        post admin_job_posting_pipeline_steps_path(job), params: { status: "expire" }

        expect(job.reload.status).to eq("expired")
        expect(response).to redirect_to(job_posting_path(job))
      end

      it "no-ops instead of raising when the transition isn't legal from the current status" do
        job.update_column(:status, "purged") # rubocop:disable Rails/SkipsModelValidations

        expect {
          post admin_job_posting_pipeline_steps_path(job), params: { status: "expire" }
        }.not_to change(PipelineStep, :count)

        expect(job.reload.status).to eq("purged")
      end
    end

    context "with a return_to param (TASK-61)" do
      it "redirects to return_to after ignore instead of the posting's own page" do
        post admin_job_posting_pipeline_steps_path(job),
             params: { status: "ignore", return_to: "/job_postings?q=rails" }

        expect(response).to redirect_to("/job_postings?q=rails")
      end

      it "redirects to return_to after expire instead of the posting's own page" do
        post admin_job_posting_pipeline_steps_path(job), params: { status: "expire", return_to: "/job_postings" }

        expect(response).to redirect_to("/job_postings")
      end

      it "ignores return_to for other status events, keeping the existing show-page redirect" do
        post admin_job_posting_pipeline_steps_path(job), params: { status: "favorite", return_to: "/job_postings" }

        expect(response).to redirect_to(job_posting_path(job))
      end

      it "falls back to the posting's own page when return_to isn't a safe local path" do
        post admin_job_posting_pipeline_steps_path(job), params: { status: "ignore", return_to: "//evil.com/phish" }

        expect(response).to redirect_to(job_posting_path(job))
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
      # header offers. (job_postings/show and admin/companies/show are the
      # remaining callers -- admin/job_postings/show was retired in favor of
      # a redirect to the unified job_postings page.)
      it "still redirects with a flash notice for a plain status change" do
        post admin_job_posting_pipeline_steps_path(job), params: { status: "favorite" }, as: :turbo_stream

        expect(job.reload.status).to eq("favorited")
        expect(response).to redirect_to(job_posting_path(job))
        follow_redirect!
        expect(response.body).to include("Activity logged")
      end
    end
  end
end
