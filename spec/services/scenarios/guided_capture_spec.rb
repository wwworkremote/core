# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::GuidedCapture do
  subject(:materialize) { described_class.call(guided_session) }

  let(:guided_session) do
    GuidedSession.create!(source_url: "https://wwworkremote.localhost/sandbox/postings/1",
                          purpose: "application_execution")
  end
  let(:arrival) do
    add_event("page_arrived", "intake", 3.minutes.ago,
              page_url: "https://job-boards.greenhouse.io/acme/jobs/4567890",
              evidence: { provider: "greenhouse", page_title: "Senior Engineer" })
  end
  let(:form) do
    add_event("application_page_arrived", "resolution", 2.minutes.ago, evidence: {
                provider: "greenhouse", field_count: 2, question_count: 1,
                fields: [
                  { field_key: "email", label: "Email", type: "email", classification: "identity", required: true },
                  { field_key: "question_1", label: "Why do you want this role?", type: "textarea",
                    classification: "screening_question", required: false }
                ]
              })
  end
  let(:submit) do
    add_event("submission_attempted", "reorientation", 1.minute.ago,
              reversibility: "irreversible", approval_state: "pending",
              evidence: { provider: "greenhouse", ats_application_id: "app_xyz789" })
  end

  before { [arrival, form, submit] }

  def add_event(kind, phase, occurred_at, attrs = {})
    guided_session.guided_session_events.create!({
      kind: kind, phase: phase, action: "act", intent: "understand the flow",
      requirement: "recommended", reversibility: "reversible", approval_state: "not_required",
      occurred_at: occurred_at
    }.merge(attrs))
  end

  def kinds_and_values(scenario)
    scenario.scenario_signatures.order(:first_observed_at, :id).pluck(:kind, :value)
  end

  it "materializes the session into a Scenario with the canonical provider" do
    scenario = materialize

    expect(scenario).to be_a(Scenario)
    expect(scenario.provider).to eq("greenhouse")
    expect(guided_session.reload.scenario_id).to eq(scenario.id)
  end

  it "stamps the correlation spine onto the materialized Scenario" do
    user_job = create(:user_job_posting)
    guided_session.update!(user_job_posting: user_job)

    scenario = materialize

    expect(scenario.guided_session_token).to eq(guided_session.session_token)
    expect(scenario.user_job_posting).to eq(user_job)
  end

  it "attributes the Scenario to a TenantIdentity derived from the source URL" do
    guided_session.update!(source_url: "https://boards.greenhouse.io/acme/jobs/4567890")

    tenant = materialize.tenant_identity

    expect(tenant).to have_attributes(provider: "greenhouse", identifier: "acme")
  end

  it "emits step, commitment_boundary, field, screening_question, and ATS identity signatures" do
    kinds = kinds_and_values(materialize)
    screening_kind = Scenarios::SignatureKind.screening_question("Why do you want this role?")

    expect(kinds).to include(
      ["step:intake.1", "page_arrived"],
      ["step:resolution.1", "application_page_arrived"],
      ["step:reorientation.1", "submission_attempted"],
      ["commitment_boundary:submission_attempted", "pending"],
      ["field:email", "email|identity|required"],
      [screening_kind, "textarea|screening_question|optional"],
      %w[job_post_id 4567890],
      %w[ats_application_id app_xyz789]
    )
  end

  it "captures job_post_id from application_page_arrived evidence when the URL does not carry it" do
    form.update!(page_url: "https://wwworkremote.localhost/sandbox/postings/1",
                 evidence: form.evidence.merge("job_post_id" => "9087654321"))

    expect(kinds_and_values(materialize)).to include(%w[job_post_id 9087654321])
  end

  it "records value-free provenance and the phase step on each signature" do
    field = materialize.scenario_signatures.find_by(kind: "field:email")

    expect(field.source).to eq("guided_session_event_id" => form.id, "extracted_from" => "evidence.fields[0]")
    expect(field.step).to eq("resolution")
  end

  it "is deterministic and idempotent across re-runs" do
    first = kinds_and_values(materialize)

    expect { described_class.call(guided_session.reload) }.not_to change(Scenario, :count)
    expect(kinds_and_values(guided_session.reload.scenario)).to eq(first)
  end

  it "never copies an entered value into a signature or its provenance" do
    poisoned = [form.evidence["fields"].first.merge("value" => "secret@example.com")] + form.evidence["fields"][1..]
    form.update!(evidence: form.evidence.merge("fields" => poisoned))

    materialize.scenario_signatures.find_each do |sig|
      expect(sig.value).not_to include("secret@example.com")
      expect(sig.source.to_s).not_to include("secret@example.com")
    end
  end

  describe "provenance protection" do
    it "blocks destroying a GuidedSessionEvent a signature points at" do
      materialize

      expect(form.destroy).to be(false)
      expect { form.reload }.not_to raise_error
    end

    it "keeps the referenced events when the session is destroyed" do
      materialize

      guided_session.destroy

      expect(GuidedSessionEvent.where(guided_session_id: guided_session.id)).to exist
    end
  end
end
