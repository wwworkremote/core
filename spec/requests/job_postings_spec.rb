# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Job Postings" do
  let(:origin) { Origin.find_or_create_by!(name: "Test Origin") }
  let(:source) { Source.find_or_create_by!(signature: "test-source", origin: origin) }
  let!(:job) {
    JobPosting.create!(
      signature: "test-1",
      title: "Senior Ruby Developer",
      company: "Acme Corp",
      published_at: 1.day.ago,
      source: source,
      status: "none"
    )
  }

  describe "GET /job_postings" do
    it "returns a success response" do
      get job_postings_path
      expect(response).to be_successful
      expect(response.body).to include("Senior Ruby Developer")
    end

    # The results grid lives inside a turbo_frame_tag (see TASK-67) so live
    # filtering doesn't need a full page reload -- any link inside that
    # frame that points somewhere else (the show page) must explicitly
    # escape it with data-turbo-frame="_top", or Turbo captures the click
    # as a frame-scoped navigation and shows "Content missing" on the show
    # page, which has no matching frame. Caught live in-browser once
    # already; this pins it so it can't silently regress.
    it "escapes the results frame on the job title link so it navigates to the show page" do
      get job_postings_path
      expect(response.body).to match(%r{<a data-turbo-frame="_top"[^>]*href="/job_postings/\d+"})
    end

    it "shows the linked Company's name when company_name is blank" do
      company = create(:company, name: "Sparta Commodities")
      JobPosting.create!(signature: "test-company-id-only", title: "Staff Backend Engineer",
                         company_id: company.id, published_at: Time.current, status: "none")

      get job_postings_path
      expect(response.body).to include("Sparta Commodities")
      expect(response.body).not_to include("/job_postings\">/job_postings")
    end

    it "falls back to a plain label instead of a broken link when no company is known" do
      JobPosting.create!(signature: "test-no-company", title: "Mystery Role",
                         published_at: Time.current, status: "none")

      get job_postings_path
      expect(response.body).to include("Unknown company")
      expect(response.body).not_to include("/job_postings\">/job_postings")
    end

    it "filters results by search query" do
      JobPosting.create!(
        signature: "test-2",
        title: "Python Architect",
        company: "Other Co",
        published_at: Time.current,
        status: "none"
      )
      get job_postings_path, params: { q: "Ruby" }
      expect(response.body).to include("Senior Ruby Developer")
      expect(response.body).not_to include("Python Architect")
    end

    it "combines a search query with another active filter, not just the query alone" do
      JobPosting.create!(
        signature: "test-contract-ruby",
        title: "Contract Ruby Developer",
        company: "Acme Corp",
        published_at: Time.current,
        status: "none",
        data: { "employment_type" => "Contract" }
      )
      get job_postings_path, params: { q: "Ruby", contract: "1" }
      expect(response.body).to include("Contract Ruby Developer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "filters out ignored, purged, and expired jobs by default" do
      create(:job_posting, signature: "ignored-1", title: "Ignored Job", status: "ignored")
      create(:job_posting, signature: "purged-1", title: "Purged Job", status: "purged")
      create(:job_posting, signature: "expired-1", title: "Expired Job", status: "expired", published_at: 1.year.ago)

      get job_postings_path
      expect(response.body).not_to include("Ignored Job")
      expect(response.body).not_to include("Purged Job")
      expect(response.body).not_to include("Expired Job")
    end

    it "orders postings with a null published_at after ones with a value" do
      create(:job_posting, signature: "null-published", title: "Null Published Job", status: "none", published_at: nil)

      get job_postings_path
      null_index = response.body.index("Null Published Job")
      recent_index = response.body.index("Senior Ruby Developer")
      expect(null_index).to be_present
      expect(recent_index).to be < null_index
    end

    it "filters to a role family when role_family=engineering_management" do
      create(:job_posting, signature: "manager-1", title: "Engineering Manager, Platform", published_at: Time.current)

      get job_postings_path, params: { role_family: "engineering_management" }
      expect(response.body).to include("Engineering Manager, Platform")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "filters to a different role family when role_family=staff_plus_ic" do
      create(:job_posting, signature: "staff-1", title: "Staff Software Engineer, Platform", published_at: Time.current)

      get job_postings_path, params: { role_family: "staff_plus_ic" }
      expect(response.body).to include("Staff Software Engineer, Platform")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "ignores an unrecognized role_family value rather than erroring" do
      get job_postings_path, params: { role_family: "not-a-real-family" }
      expect(response).to be_successful
      expect(response.body).to include("Senior Ruby Developer")
    end

    it "filters by location text" do
      create(:job_posting, signature: "chicago-1", title: "Chicago Loop Engineer",
                           location: "Chicago, IL", published_at: Time.current)

      get job_postings_path, params: { location: "Chicago" }
      expect(response.body).to include("Chicago Loop Engineer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "filters to remote postings via the structured data flag, not just location text" do
      # Regression companion to Geo::CommuteZone's key fix -- the primary
      # enrichment pipeline (extension captures included) writes
      # data["remote"], and this filter needs to honor that even when the
      # location string itself never says "remote".
      create(:job_posting, signature: "remote-flagged", title: "Flagged Remote Engineer",
                           location: "Austin, TX", data: { "remote" => true }, published_at: Time.current)

      get job_postings_path, params: { remote: "1" }
      expect(response.body).to include("Flagged Remote Engineer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "filters to contract postings when contract=1" do
      create(:job_posting, signature: "contract-1", title: "Contract DevOps Engineer",
                           data: { "employment_type" => "Contract" }, published_at: Time.current)

      get job_postings_path, params: { contract: "1" }
      expect(response.body).to include("Contract DevOps Engineer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "combines location and remote as OR, not AND" do
      create(:job_posting, signature: "chicago-2", title: "Chicago Onsite Engineer",
                           location: "Chicago, IL", published_at: Time.current)
      create(:job_posting, signature: "remote-2", title: "Fully Remote Engineer",
                           location: "Remote", published_at: Time.current)

      get job_postings_path, params: { location: "Chicago", remote: "1" }
      expect(response.body).to include("Chicago Onsite Engineer")
      expect(response.body).to include("Fully Remote Engineer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end
  end

  describe "GET /job_postings?sort=match_score" do
    let(:current_user) {
      User.find_or_create_by!(email: "mike@just3ws.com") { |u|
        u.name = "Mike"; u.password = "password"
      }
    }

    it "orders postings by the current user's match_score, highest first" do
      low = create(:job_posting, signature: "low-match", title: "Low Match Job", published_at: Time.current)
      high = create(:job_posting, signature: "high-match", title: "High Match Job", published_at: Time.current)
      create(:user_job_posting, user: current_user, job_posting: low, match_score: 20)
      create(:user_job_posting, user: current_user, job_posting: high, match_score: 90)

      get job_postings_path(sort: "match_score")

      high_index = response.body.index("High Match Job")
      low_index = response.body.index("Low Match Job")
      expect(high_index).to be < low_index
    end

    it "keeps unscored postings in the list, sorted after scored ones" do
      scored = create(:job_posting, signature: "scored", title: "Scored Job", published_at: Time.current)
      create(:user_job_posting, user: current_user, job_posting: scored, match_score: 50)
      # `job` (from the outer let!) has no UserJobPosting at all

      get job_postings_path(sort: "match_score")

      expect(response.body).to include("Scored Job")
      expect(response.body).to include(job.title)
    end

    it "displays the score and tags badge on a scored posting's card" do
      scored = create(:job_posting, signature: "scored-tags", title: "Tagged Job", published_at: Time.current)
      create(:user_job_posting, user: current_user, job_posting: scored, match_score: 85,
                                match_tags: %w[remote-strict ruby-heavy])

      get job_postings_path(sort: "match_score")

      expect(response.body).to include("85% match")
      expect(response.body).to include("remote-strict")
      expect(response.body).to include("ruby-heavy")
    end

    it "ignores an invalid sort value rather than erroring" do
      get job_postings_path(sort: "not-a-real-sort")
      expect(response).to be_successful
    end
  end

  describe "GET /job_postings/:id" do
    it "returns a success response" do
      get job_posting_path(job)
      expect(response).to be_successful
      expect(response.body).to include("Senior Ruby Developer")
      expect(response.body).to include("Acme Corp")
    end

    it "shows the reformat button when the posting has a body and isn't already reformatting" do
      job.update!(body: "raw description text")
      get job_posting_path(job)
      expect(response.body).to include("Reformat with AI")
    end

    it "shows a pending indicator instead of the button while reformatting" do
      job.update!(body: "raw description text", data: { "reformatting" => true })
      get job_posting_path(job)
      expect(response.body).to include("Reformatting...")
      expect(response.body).not_to include("Reformat with AI")
    end

    it "prefers the AI-reformatted body over the raw body when present" do
      job.update!(body: "raw <b>text</b>", data: { "formatted_body" => "## Clean Heading" })
      get job_posting_path(job)
      expect(response.body).to include("Clean Heading")
    end

    it "carries the same-host referer through to the Not Interested/Expired buttons as return_to" do
      get job_posting_path(job), headers: { "HTTP_REFERER" => "http://www.example.com/job_postings?q=ruby" }
      expect(response.body).to include('name="return_to" value="/job_postings?q=ruby"')
    end

    it "omits return_to when there's no referer" do
      get job_posting_path(job)
      expect(response.body).not_to include("return_to=")
    end

    it "omits return_to when the referer is a different host" do
      get job_posting_path(job), headers: { "HTTP_REFERER" => "http://evil.example/steal" }
      expect(response.body).not_to include("return_to=")
    end

    it "shows the source's origin name" do
      get job_posting_path(job)
      expect(response.body).to include("Test Origin")
    end

    it "shows the employment type from data when present" do
      job.update!(data: { "employment_type" => "Contract" })
      get job_posting_path(job)
      expect(response.body).to include("Contract")
    end

    it "links the company name to its profile page when a matching Company exists" do
      company = create(:company, name: "Acme Corp")
      get job_posting_path(job)
      expect(response.body).to include(company_path(company))
    end

    it "falls back to the filtered index link when no matching Company exists" do
      get job_posting_path(job)
      expect(response.body).to include(job_postings_path(company: "Acme Corp"))
    end

    it "shows the Enrich Data action" do
      get job_posting_path(job)
      expect(response.body).to include("Enrich Data")
    end

    it "shows Purge instead of Restore for a non-purged posting" do
      get job_posting_path(job)
      expect(response.body).to include("Purge")
      expect(response.body).not_to include("Restore")
    end

    it "shows Restore instead of Purge for a purged posting" do
      job.purge!
      get job_posting_path(job)
      expect(response.body).to include("Restore")
      expect(response.body).not_to include(">Purge<")
    end

    it "offers Delete Permanently only once a posting is purged (TASK-69.4)" do
      get job_posting_path(job)
      expect(response.body).not_to include("Delete Permanently")

      job.purge!
      get job_posting_path(job)
      expect(response.body).to include("Delete Permanently")
      expect(response.body).to include(admin_job_posting_path(job))
    end

    it "shows a Lead badge linking to the admin lead when the posting was captured via the extension" do
      lead = create(:lead, job_posting: job, provider: "linkedin")
      get job_posting_path(job)
      expect(response.body).to include("Linkedin")
      expect(response.body).to include(admin_lead_path(lead))
    end

    it "omits the Lead badge when the posting has no lead" do
      get job_posting_path(job)
      expect(response.body).not_to include("Captured via the extension")
    end

    it "renders a lazily-loaded similar-postings frame pointing at the admin frame endpoint" do
      get job_posting_path(job)
      expect(response.body).to include('id="semantic_matches"')
      expect(response.body).to include(admin_job_posting_path(job, frame: "semantic_matches"))
    end

    it "shows what changed for a version, not just the bare event/time" do
      job.update!(title: "A New Title")

      get job_posting_path(job)

      expect(response.body).to include("Title: Senior Ruby Developer → A New Title")
    end

    context "cover letter panel" do
      let(:current_user) {
        User.find_or_create_by!(email: "mike@just3ws.com") { |u|
          u.name = "Mike"; u.password = "password"
        }
      }

      it "renders the generated cover letter as its own panel, distinct from notes, with a copy action" do
        create(:user_job_posting, user: current_user, job_posting: job, cover_letter: "Dear Hiring Manager...",
                                  notes: "my own private notes")

        get job_posting_path(job)

        expect(response.body).to include("Dear Hiring Manager")
        expect(response.body).to include("Cover Letter")
        expect(response.body).to include('data-action="clipboard#copy"')
        expect(response.body).to include("my own private notes")
      end

      it "omits the cover letter panel when none has been generated yet" do
        get job_posting_path(job)
        expect(response.body).not_to include('data-controller="clipboard"')
      end
    end

    context "application Q&A panel" do
      let(:current_user) {
        User.find_or_create_by!(email: "mike@just3ws.com") { |u|
          u.name = "Mike"; u.password = "password"
        }
      }

      it "lists existing questions with their answer and source badge" do
        create(:application_question, user: current_user, job_posting: job, question_text: "Why this role?",
                                      answer_text: "Because it's a great fit.", answer_source: "ai")

        get job_posting_path(job)

        expect(response.body).to include("Why this role?")
        expect(response.body).to include("Because it&#39;s a great fit.")
        expect(response.body).to include("AI Generated")
      end

      it "shows a From Profile badge for canned answers" do
        create(:application_question, user: current_user, job_posting: job, question_text: "Years of experience?",
                                      answer_text: "10 years", answer_source: "canned")

        get job_posting_path(job)

        expect(response.body).to include("From Profile")
      end

      it "shows a fallback message when a question has no answer yet" do
        create(:application_question, user: current_user, job_posting: job, question_text: "Unanswered question",
                                      answer_text: nil)

        get job_posting_path(job)

        expect(response.body).to include("Unanswered question")
        expect(response.body).to include("Answer generation failed")
      end
    end
  end

  describe "POST /job_postings/:id/reformat" do
    before { ActiveJob::Base.queue_adapter = :test }

    it "marks the posting as reformatting and enqueues the background job" do
      job.update!(body: "raw description text")

      expect {
        post reformat_job_posting_path(job), as: :turbo_stream
      }.to have_enqueued_job(JobPostingReformatJob).with(job.id)

      expect(job.reload.data["reformatting"]).to be true
    end

    it "responds with a turbo stream replacing the description block" do
      job.update!(body: "raw description text")
      post reformat_job_posting_path(job), as: :turbo_stream
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include("Reformatting...")
    end
  end
end
