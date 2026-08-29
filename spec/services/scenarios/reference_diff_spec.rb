# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::ReferenceDiff do
  it "reports gained, lost, and reordered signature kinds" do
    reference = create(:scenario, provider: "greenhouse")
    candidate = create(:scenario, provider: "greenhouse")
    create_signature(reference, "job_post_id", 3.minutes.ago)
    create_signature(reference, "ats_application_id", 2.minutes.ago)
    create_signature(candidate, "ats_application_id", 3.minutes.ago)
    create_signature(candidate, "session_cookie", 2.minutes.ago)
    create_signature(candidate, "job_post_id", 1.minute.ago)

    expect(described_class.call(candidate, reference: reference)).to include(
      candidate: %w[ats_application_id session_cookie job_post_id],
      reference: %w[job_post_id ats_application_id],
      gained: ["session_cookie"],
      lost: [],
      reordered: true
    )
  end

  it "reports a same-kind value change and buckets the diff by dimension" do
    reference = scenario_with([["step:intake.1", "x"], ["field:email", "email|identity|required"]])
    candidate = scenario_with([
                                ["step:intake.1", "x"],
                                ["field:email", "text|identity|optional"],
                                ["screening_question:v1:abc", "textarea|screening_question|optional"]
                              ])

    result = described_class.call(candidate, reference: reference)

    expect(result[:changed]).to eq(["field:email"])
    expect(result[:dimensions]["screening_question"]).to eq(gained: ["screening_question:v1:abc"], lost: [],
                                                            changed: [])
    expect(result[:dimensions]["field"]).to eq(gained: [], lost: [], changed: ["field:email"])
  end

  it "treats ATS identity signatures as presence-only, never a value change" do
    reference = create(:scenario, provider: "greenhouse")
    candidate = create(:scenario, provider: "greenhouse")
    create(:scenario_signature, scenario: reference, kind: "job_post_id", value: "111", first_observed_at: 1.minute.ago)
    create(:scenario_signature, scenario: candidate, kind: "job_post_id", value: "999", first_observed_at: 1.minute.ago)

    result = described_class.call(candidate, reference: reference)

    expect(result[:changed]).to eq([])
    expect(result[:dimensions]["ats_identity"]).to eq(gained: [], lost: [], changed: [])
  end

  def create_signature(scenario, kind, observed_at)
    create(:scenario_signature, scenario: scenario, kind: kind, first_observed_at: observed_at)
  end
end
