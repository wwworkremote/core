# frozen_string_literal: true

require "rails_helper"

RSpec.describe "JobPostingTriage" do
  describe "GET /job_postings/triage" do
    it "shows the most recent untriaged posting" do
      # published_at 1.year.from_now, not just 1.hour.ago -- guards against
      # unrelated "none"-status postings that other specs may leave behind
      # in the shared test DB (see TASK-56) outranking this one by recency.
      create(:job_posting, status: "favorited", published_at: 1.year.from_now)
      newest = create(:job_posting, status: "none", published_at: 1.year.from_now)
      create(:job_posting, status: "none", published_at: 1.day.ago)

      get job_posting_triage_path

      expect(response.body).to include(newest.title)
    end

    it "shows an empty state when nothing is left to triage" do
      create(:job_posting, status: "favorited")

      get job_posting_triage_path

      expect(response).to have_http_status(:ok)
    end

    context "with a skip param" do
      it "excludes the skipped posting from this session's queue without changing its status" do
        skipped = create(:job_posting, status: "none", title: "Skip Me Engineer", published_at: 1.hour.ago)
        # published_at 1.year.from_now for the same TASK-56 pollution-guard
        # reason as the "most recent" spec above -- it needs to reliably
        # rank first once `skipped` is excluded.
        next_up = create(:job_posting, status: "none", title: "Show Me Engineer", published_at: 1.year.from_now)

        get job_posting_triage_path(skip: skipped.id)

        expect(response.body).to include(next_up.title)
        expect(response.body).not_to include(skipped.title)
        expect(skipped.reload.status).to eq("none")
        expect(skipped.pipeline_steps).to be_empty
      end
    end

    context "with reset_skips" do
      it "clears the session's skipped list so a previously skipped posting reappears" do
        skipped = create(:job_posting, status: "none", published_at: 1.year.from_now)
        get job_posting_triage_path(skip: skipped.id)
        expect(response.body).not_to include(skipped.title)

        get job_posting_triage_path(reset_skips: "true")

        expect(response.body).to include(skipped.title)
      end
    end

    context "after a decision was recorded via the triage flow" do
      it "offers a Back link to the just-triaged posting so a wrong disposition can be fixed" do
        decided = create(:job_posting, status: "none", title: "Just Decided Engineer")
        post admin_job_posting_pipeline_steps_path(decided), params: { status: "favorite", from_triage: "true" }

        get job_posting_triage_path

        expect(response.body).to include(job_posting_path(decided))
        expect(response.body).to include(decided.title)
      end
    end

    it "has no Back link when nothing has been triaged yet this session" do
      get job_posting_triage_path

      expect(response.body).not_to include('data-triage-target="back"')
    end
  end
end
