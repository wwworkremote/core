# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionArchetypes::SuggestedReadiness do
  def sha = Digest::SHA256.hexdigest(SecureRandom.hex)

  def verdicts(archetype, count, verdict:, edit_distance: 0)
    count.times do
      archetype.answer_proposal_verdicts.create!(strategy_source: "ai", verdict: verdict,
                                                 proposed_text_sha256: sha, edit_distance: edit_distance)
    end
  end

  it "suggests needs_human below the sample-size floor" do
    archetype = create(:question_archetype, question_kind: "eligibility")
    verdicts(archetype, 2, verdict: "accepted")

    expect(described_class.call(archetype).readiness_class).to eq("needs_human")
  end

  it "suggests deterministic for a mostly-accepted eligibility question" do
    archetype = create(:question_archetype, question_kind: "eligibility")
    verdicts(archetype, 9, verdict: "accepted")
    verdicts(archetype, 1, verdict: "edited", edit_distance: 5)

    expect(described_class.call(archetype).readiness_class).to eq("deterministic")
  end

  it "suggests needs_human when proposals get heavily rewritten" do
    archetype = create(:question_archetype, question_kind: "motivation")
    verdicts(archetype, 6, verdict: "edited", edit_distance: 120)

    expect(described_class.call(archetype).readiness_class).to eq("needs_human")
  end
end
