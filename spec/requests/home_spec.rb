# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home" do
  let(:user) do
    User.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")) do |u|
      u.name = ENV.fetch("ADMIN_NAME", "mike")
      u.password = ENV.fetch("ADMIN_PASSWORD", "password")
    end
  end

  describe "GET /" do
    it "returns a success response" do
      get root_path
      expect(response).to be_successful
    end

    it "shows the Needs Follow-up section for an idle application" do
      job_posting = create(:job_posting, title: "Idle Role")
      ujp = create(:user_job_posting, user: user, job_posting: job_posting, status: "applied")
      PipelineStep.create!(job_posting: job_posting, user: user, status: "applied",
                           created_at: UserJobPosting::IDLE_AFTER.ago - 1.day)

      get root_path

      expect(response.body).to include("Needs Follow-up")
      expect(response.body).to include("Idle Role")
      expect(ujp).to be_persisted
    end

    it "omits the section when nothing is idle" do
      get root_path
      expect(response.body).not_to include("Needs Follow-up")
    end

    it "shows Never when no application has ever been logged" do
      get root_path
      expect(response.body).to include("Never")
      expect(response.body).to include("Since Last Application")
    end

    it "shows time since the most recent live PipelineStep apply event" do
      job_posting = create(:job_posting)
      PipelineStep.create!(job_posting: job_posting, user: user, status: "applied", created_at: 2.days.ago)

      get root_path

      expect(response.body).to include("Since Last Application")
      expect(response.body).not_to include("Never")
    end

    it "prefers an imported applied_at when it's more recent than any PipelineStep" do
      job_posting = create(:job_posting)
      PipelineStep.create!(job_posting: job_posting, user: user, status: "applied", created_at: 10.days.ago)
      create(:user_job_posting, user: user, job_posting: job_posting, status: "applied", applied_at: 1.hour.ago)

      get root_path

      expect(response.body).to include("about 1 hour")
    end

    it "surfaces a scheduled interview with a link to its prep pack" do
      job_posting = create(:job_posting, title: "Interview Role")
      create(:user_job_posting, user: user, job_posting: job_posting, status: "applied")
      create(:interview_session, user: user, job_posting: job_posting, scheduled_at: 2.days.from_now)

      get root_path

      expect(response.body).to include("Interviews")
      expect(response.body).to include("Interview Role")
      expect(response.body).to include(job_posting_path(job_posting, anchor: "interview-prep"))
    end

    it "lists favorited postings as active leads and applied ones as awaiting response" do
      lead = create(:job_posting, title: "Lead Role")
      applied = create(:job_posting, title: "Applied Role")
      create(:user_job_posting, user: user, job_posting: lead, status: "favorited")
      create(:user_job_posting, user: user, job_posting: applied, status: "applied")

      get root_path

      expect(response.body).to include("Active Leads")
      expect(response.body).to include("Lead Role")
      expect(response.body).to include("Awaiting Response")
      expect(response.body).to include("Applied Role")
    end

    it "surfaces the untriaged count and oldest-untriaged age" do
      job_posting = create(:job_posting)
      ujp = create(:user_job_posting, user: user, job_posting: job_posting, status: "none")
      ujp.update!(created_at: 40.days.ago)

      get root_path

      expect(response.body).to include("Untriaged")
      expect(response.body).to include("Oldest Untriaged")
      expect(response.body).to include("1</div>") # untriaged count
    end
  end
end
