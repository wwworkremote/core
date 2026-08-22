# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("lib/wwwr")
require Rails.root.join("lib/wwwr/interop")
require Rails.root.join("lib/wwwr/queue_status")
require Rails.root.join("lib/wwwr/cli")

RSpec.describe Wwwr::CLI do
  subject(:cli) { described_class.new }

  describe "status" do
    it "prints a pipeline health summary" do
      expect { cli.run(["status"]) }.to output(/Job postings:/).to_stdout
    end

    it "surfaces an unclaimed job's queue depth and age (regression: 2026-08-17 dead-worker incident)" do
      job_posting = create(:job_posting)
      JobPostingReformatJob.perform_later(job_posting.id)

      expect { cli.run(["status"]) }.to output(/Unclaimed pending jobs: [1-9]/).to_stdout
      expect { cli.run(["status"]) }.to output(/Oldest unclaimed:.*JobPostingReformatJob/).to_stdout
    end
  end

  describe "postings" do
    it "lists postings matching the given filter" do
      create(:job_posting, title: "Remote Ruby Dev", data: { "remote" => true })
      create(:job_posting, title: "Onsite Ruby Dev", signature: "onsite-1")

      expect { cli.run(["postings", "--remote"]) }.to output(/Remote Ruby Dev/).to_stdout
      expect { cli.run(["postings", "--remote"]) }.not_to output(/Onsite Ruby Dev/).to_stdout
    end

    it "reports when no postings match" do
      expect { cli.run(["postings", "--company=Nobody"]) }.to output(/No postings match/).to_stdout
    end
  end

  describe "transition" do
    # The CLI now records against the one local User's UserJobPosting as well
    # as the posting, same as the extension does -- so the single-user
    # assumption Wwwr::Interop already makes has to hold here too.
    let!(:user) { create(:user) }

    it "applies a legal event and logs a pipeline step" do
      posting = create(:job_posting, status: "none")

      cli.run(["transition", posting.id.to_s, "favorite"])

      expect(posting.reload.status).to eq("favorited")
      expect(posting.pipeline_steps.last.status).to eq("favorite")
    end

    # The bug this closes: the CLI moved JobPosting.status and wrote a
    # PipelineStep while UserJobPosting.status stayed put, so the audit trail
    # claimed a pipeline advance that the user's own record never saw.
    it "keeps the user's tracked status in step with the posting" do
      posting = create(:job_posting, status: "none")

      cli.run(["transition", posting.id.to_s, "favorite"])

      tracked = user.user_job_postings.find_by(job_posting: posting)
      expect(tracked.status).to eq("favorited")
    end

    it "refuses an illegal transition without raising" do
      posting = create(:job_posting, status: "purged")

      expect { cli.run(["transition", posting.id.to_s, "ignore"]) }.not_to raise_error
      expect(posting.reload.status).to eq("purged")
    end

    it "reports an unknown posting id instead of raising" do
      expect { cli.run(%w[transition 999999 favorite]) }.to output(/not found/).to_stdout
    end
  end

  describe "match" do
    it "requires --source for attribution" do
      posting = create(:job_posting)

      expect { cli.run(["match", posting.id.to_s]) }.to output(/Missing --source/).to_stdout
    end

    it "reports an unknown posting id instead of raising" do
      expect { cli.run(%w[match 999999 --source=spec]) }.to output(/not found/).to_stdout
    end

    it "reads an existing analysis without calling the LLM" do
      user = create(:user)
      posting = create(:job_posting)
      create(:user_job_posting, user: user, job_posting: posting, match_analysis: "Solid fit.", match_score: 90)
      allow(LLM::ProfileMatcher).to receive(:call)

      expect { cli.run(["match", posting.id.to_s, "--source=spec"]) }.to output(/Solid fit\./).to_stdout
      expect(LLM::ProfileMatcher).not_to have_received(:call)
    end

    it "tells the caller to --escalate when there is no analysis on file" do
      create(:user)
      posting = create(:job_posting)

      expect { cli.run(["match", posting.id.to_s, "--source=spec"]) }.to output(/Pass --escalate/).to_stdout
    end

    it "runs the profile matcher and prints its output when escalated" do
      user = create(:user)
      posting = create(:job_posting)
      allow(LLM::ProfileMatcher).to receive(:call).with(user, posting).and_return(success: true, output: "Fresh scan.")

      expect { cli.run(["match", posting.id.to_s, "--source=spec", "--escalate"]) }.to output(/Fresh scan\./).to_stdout
    end
  end
end
