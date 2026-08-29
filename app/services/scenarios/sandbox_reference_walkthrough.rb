# frozen_string_literal: true

# Builds the canonical Greenhouse sandbox Reference Scenario from a full
# application_execution guided session (ADR 009, TASK-118). It goes through the
# same Scenarios::Capture.from_guided_session path a real extension walkthrough
# uses, so the reference and the candidates diffed against it share one capture
# shape. Reproducible -- re-run whenever the sandbox form
# (app/views/sandbox/postings/show.html.erb) changes. The real-extension browser
# dogfood remains the final human confirmation.
class Scenarios::SandboxReferenceWalkthrough
  PROVIDER = "greenhouse"
  POSTING_URL = "https://wwworkremote.localhost/sandbox/postings/1"

  # Mirrors app/views/sandbox/postings/show.html.erb exactly.
  FORM_FIELDS = [
    { field_key: "first_name", label: "First Name", type: "text", classification: "identity", required: false },
    { field_key: "last_name", label: "Last Name", type: "text", classification: "identity", required: false },
    { field_key: "email", label: "Email", type: "email", classification: "identity", required: false },
    { field_key: "question_1", label: "Why do you want to work here?", type: "textarea",
      classification: "screening_question", required: false },
    { field_key: "question_2", label: "What is your notice period?", type: "text",
      classification: "screening_question", required: false },
    { field_key: "8", label: "Gender", type: "select", classification: "demographic", required: false }
  ].freeze

  DEFAULT_EVENT = { intent: "Reference walkthrough of the sandbox provider", requirement: "required",
                    reversibility: "reversible", approval_state: "not_required" }.freeze

  def self.call
    new.call
  end

  def call
    scenario = Scenarios::Capture.from_guided_session(build_session)
    Scenarios::PromoteReference.call(scenario)
    scenario
  end

  private

  def build_session
    session = GuidedSession.create!(source_url: POSTING_URL, purpose: "application_execution")
    job_url = "https://job-boards.greenhouse.io/acmesandbox/jobs/#{SecureRandom.random_number(10**10)}"
    [arrival_event(job_url), form_event(job_url), submission_event, confirmation_event(job_url)]
      .each { |attrs| add_event(session, attrs) }
    session
  end

  def add_event(session, attrs)
    attrs = DEFAULT_EVENT.merge(action: attrs[:kind].to_s.humanize, **attrs)
    session.guided_session_events.create!(attrs)
  end

  def arrival_event(job_url)
    { kind: "page_arrived", phase: "intake", occurred_at: 4.minutes.ago, page_url: job_url,
      evidence: { provider: PROVIDER, page_title: "Senior Backend Engineer - Acme Sandbox Co" } }
  end

  def form_event(job_url)
    { kind: "application_page_arrived", phase: "resolution", occurred_at: 3.minutes.ago, page_url: job_url,
      evidence: { provider: PROVIDER, field_count: FORM_FIELDS.size, question_count: 2, fields: FORM_FIELDS } }
  end

  def submission_event
    { kind: "submission_attempted", phase: "reorientation", occurred_at: 2.minutes.ago,
      reversibility: "irreversible", approval_state: "approved", evidence: { provider: PROVIDER } }
  end

  def confirmation_event(job_url)
    { kind: "application_submitted", phase: "reorientation", occurred_at: 1.minute.ago,
      page_url: "#{job_url}/confirmation", evidence: { provider: PROVIDER, ats_application_id: SecureRandom.hex(8) } }
  end
end
