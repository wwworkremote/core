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

  def create_signature(scenario, kind, observed_at)
    create(:scenario_signature, scenario: scenario, kind: kind, first_observed_at: observed_at)
  end
end
