# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GuidedSessions" do
  # Mirrors Authenticatable#current_user: the one admin account the app resolves to.
  def current_user
    @current_user ||= User.find_or_create_by!(email: "mike@just3ws.com") do |u|
      u.name = "mike"
      u.password = "password"
    end
  end

  describe "GET /guided_sessions" do
    it "lists recent sessions with their posting, company, purpose and state" do
      company = create(:company, name: "Acme Co")
      posting = create(:job_posting, company: company, title: "Staff Engineer")
      application = current_user.user_job_postings.create!(job_posting: posting)
      GuidedSession.create!(source_url: "https://boards.greenhouse.io/acme/jobs/1", purpose: "application_execution",
                            user_job_posting: application, status: "completed")

      get guided_sessions_path

      expect(response).to be_successful
      expect(response.body).to include("Staff Engineer").and include("Acme Co").and include("Application execution")
    end
  end

  describe "GET /guided_sessions/new" do
    it "renders the copied posting URL intake" do
      get new_guided_session_path

      expect(response).to be_successful
      expect(response.body).to include("Start a guided application session")
      expect(response.body).to include("Job posting URL")
      expect(response.body).to include("Research the application")
      expect(response.body).to include("Work toward applying")
      document = response.parsed_body
      expect(document.at_css('input[value="application_research"]')["checked"]).to eq("checked")
    end
  end

  describe "POST /guided_sessions" do
    it "starts an intake session for a copied posting URL" do
      expect {
        post guided_sessions_path, params: {
          guided_session: {
            source_url: "https://jobs.example.com/roles/42",
            purpose: "application_research"
          }
        }
      }.to change(GuidedSession, :count).by(1)

      session = GuidedSession.order(:id).last
      expect(session.source_url).to eq("https://jobs.example.com/roles/42")
      expect(session.provider).to eq("jobs.example.com")
      expect(session.phase).to eq("intake")
      expect(session.status).to eq("active")
      expect(session.purpose).to eq("application_research")
      expect(response).to redirect_to(guided_session_path(session))
    end

    it "rejects an unknown session purpose" do
      expect {
        post guided_sessions_path, params: {
          guided_session: { source_url: "https://jobs.example.com/roles/42", purpose: "auto_submit" }
        }
      }.not_to change(GuidedSession, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a non-http posting URL" do
      expect {
        post guided_sessions_path, params: {
          guided_session: { source_url: "javascript:alert(1)" }
        }
      }.not_to change(GuidedSession, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /guided_sessions/:id" do
    it "shows the current pump-track phase and next move" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42", purpose: "application_research")

      get guided_session_path(session)

      expect(response).to be_successful
      expect(response.body).to include("Intake")
      expect(response.body).to include("Review the posting")
      expect(response.body).to include("Research mode")
      expect(response.body).to include("Application research")
      expect(response.body).to include("Open research flow")
      expect(response.body).to include("guided_session_token=#{session.session_token}")
    end

    it "summarises the fields filled during the session without showing values (AC#2)" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42")
      application = create(:user_job_posting)
      create(:application_field_answer, user_job_posting: application, field_key: "phone", field_label: "Phone number",
                                        answer: "555-0100", answer_source: "profile",
                                        guided_session_token: session.session_token)

      get guided_session_path(session)

      expect(response.body).to include("Field activity this session").and include("Phone number")
      expect(response.body).not_to include("555-0100")
    end

    it "preserves existing source parameters and replaces stale correlation" do
      session = GuidedSession.create!(
        source_url: "https://jobs.example.com/roles/42?source=board&guided_session_token=stale"
      )

      expect(session.tracked_source_url).to eq(
        "https://jobs.example.com/roles/42?source=board&guided_session_token=#{session.session_token}" \
        "&guided_session_purpose=application_execution"
      )
    end

    it "carries the session purpose so content.js can pick the capture path (TASK-134 AC#3)" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42",
                                      purpose: "application_research")

      expect(session.tracked_source_url).to include("guided_session_purpose=application_research")
    end

    it "renders the pump-track playback map and durable resume position" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42", playback_position: 2)

      get guided_session_path(session)

      expect(response).to be_successful
      expect(response.body).to include('data-controller="guided-session-playback"')
      expect(response.body).to include("Playback position: 2")
      expect(response.body).to include("Play lap")
    end
  end

  describe "PATCH /guided_sessions/:id/playback" do
    it "persists the playback position for a later handoff" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42")

      patch playback_guided_session_path(session), params: { position: 3 }

      expect(response).to have_http_status(:ok)
      expect(session.reload.playback_position).to eq(3)
      expect(response.parsed_body).to include("position" => 3)
    end

    it "rejects a negative playback position" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42")

      patch playback_guided_session_path(session), params: { position: -1 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session.reload.playback_position).to eq(0)
    end
  end

  describe "reference comparison" do
    let(:session) do
      s = GuidedSession.create!(source_url: "https://wwworkremote.localhost/sandbox/postings/1",
                                purpose: "application_execution")
      s.guided_session_events.create!(kind: "application_page_arrived", phase: "resolution", action: "observe",
                                      intent: "map the flow", requirement: "recommended", reversibility: "reversible",
                                      approval_state: "not_required", occurred_at: 1.minute.ago,
                                      evidence: { provider: "greenhouse", fields: [
                                        { field_key: "email", label: "Email", type: "email",
                                          classification: "identity", required: true }
                                      ] })
      s
    end

    def build_reference
      # field:phone before the step the candidate reaches, so it lands inside
      # Reached Scope and registers as drift (a field the run should have seen).
      ref = scenario_with([["field:phone", "tel|identity|required"],
                           ["step:resolution.1", "application_page_arrived"]], provider: "greenhouse")
      create(:reference_scenario, scenario: ref)
    end

    it "lists context-gathering opportunities for a provider with unobserved optional signatures" do
      workday = GuidedSession.create!(source_url: "https://acme.wd5.myworkdayjobs.com/careers/job/1",
                                      purpose: "application_execution")
      workday.guided_session_events.create!(kind: "application_page_arrived", phase: "resolution", action: "observe",
                                            intent: "map", requirement: "recommended", reversibility: "reversible",
                                            approval_state: "not_required", occurred_at: 1.minute.ago,
                                            evidence: { provider: "workday" })
      Scenarios::GuidedCapture.call(workday)

      get guided_session_path(workday)

      expect(response.body).to include("Opportunities to gather more context").and include("candidate_id")
    end

    it "runs exactly one automatic comparison on the first completion and none on a repeat" do
      build_reference

      expect { post complete_guided_session_path(session) }
        .to change { session.reference_comparisons.where(trigger: "automatic").count }.from(0).to(1)
      post complete_guided_session_path(session)

      expect(session.reference_comparisons.where(trigger: "automatic").count).to eq(1)
      expect(session.reload.status).to eq("completed")
    end

    it "creates a new manual run on each compare and never advances the session" do
      build_reference
      original = session.attributes.slice("phase", "status", "playback_position")

      expect { post compare_guided_session_path(session) }
        .to change { session.reference_comparisons.where(trigger: "manual").count }.by(1)
      post compare_guided_session_path(session)

      expect(session.reference_comparisons.where(trigger: "manual").count).to eq(2)
      expect(session.reload.attributes.slice("phase", "status", "playback_position")).to eq(original)
    end

    it "renders the coverage map, a drift finding, and a disposition control" do
      build_reference
      post compare_guided_session_path(session)

      get guided_session_path(session)

      expect(response.body).to include("Reference comparison")
      expect(response.body).to include("Coverage")
      expect(response.body).to include("field:phone")
      expect(response.body).to include("Reference incomplete or stale")
    end

    it "shows a carried-forward suggestion without dispositioning the new finding" do
      reference = build_reference
      prior = create(:reference_comparison, provider: "greenhouse", reference_scenario: reference)
      prior_finding = prior.comparison_findings.create!(category: "drift", dimension: "field", locator: "field:phone")
      prior_finding.finding_dispositions.create!(value: "expected_persona_variation", reviewer: "mike")

      post compare_guided_session_path(session)
      finding = session.reference_comparisons.order(:id).last.comparison_findings.find_by(locator: "field:phone")

      expect(finding.suggested_disposition).to eq(prior_finding.finding_dispositions.last)
      expect(finding.dispositioned?).to be(false)

      get guided_session_path(session)
      expect(response.body).to include("Suggested from an earlier run")
    end

    it "records a disposition from the review page" do
      build_reference
      post compare_guided_session_path(session)
      finding = session.reference_comparisons.order(:id).last.comparison_findings.find_by(locator: "field:phone")

      expect {
        post finding_dispositions_guided_session_path(session, finding_id: finding.id),
             params: { value: "provider_site_drift", rationale: "greenhouse dropped the phone field" }
      }.to change(FindingDisposition, :count).by(1)
      expect(finding.reload.current_disposition.value).to eq("provider_site_drift")
    end

    it "says so when no reference exists, without raising" do
      get guided_session_path(session)
      expect(response).to be_successful

      post compare_guided_session_path(session)
      get guided_session_path(session)

      expect(response).to be_successful
      expect(response.body).to include("No reference scenario exists for").and include("greenhouse")
    end
  end

  describe "POST /job_postings/:id/start_supervised_application" do
    let(:job_posting) { create(:job_posting, target_url: "https://boards.greenhouse.io/acme/jobs/42") }

    it "creates the tracked application when none exists and links a session to it" do
      expect {
        post start_supervised_application_job_posting_path(job_posting)
      }.to change(GuidedSession, :count).by(1).and change(UserJobPosting, :count).by(1)

      session = GuidedSession.order(:id).last
      expect(session.user_job_posting.job_posting).to eq(job_posting)
      expect(session.purpose).to eq("application_execution")
      expect(session.source_url).to eq("https://boards.greenhouse.io/acme/jobs/42")
      expect(response).to redirect_to(guided_session_path(session))
    end

    it "reuses an existing tracked application" do
      existing = current_user.user_job_postings.create!(job_posting: job_posting)

      expect {
        post start_supervised_application_job_posting_path(job_posting)
      }.to change(GuidedSession, :count).by(1)

      expect(UserJobPosting.count).to eq(1)
      expect(GuidedSession.order(:id).last.user_job_posting).to eq(existing)
    end

    it "does not advance the tracked application's pipeline state" do
      post start_supervised_application_job_posting_path(job_posting)

      expect(GuidedSession.order(:id).last.user_job_posting.status).not_to eq("applied")
    end

    it "redirects back with an alert when the posting has no application URL" do
      urlless = create(:job_posting, target_url: nil)

      expect {
        post start_supervised_application_job_posting_path(urlless)
      }.not_to change(GuidedSession, :count)

      expect(response).to redirect_to(job_posting_path(urlless))
      expect(flash[:alert]).to match(/no application URL/i)
    end
  end
end
