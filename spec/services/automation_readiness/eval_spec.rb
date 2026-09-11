# frozen_string_literal: true

require "rails_helper"

RSpec.describe AutomationReadiness::Eval do
  def sha = Digest::SHA256.hexdigest(SecureRandom.hex)

  it "reports acceptance rate and median edit distance by strategy for archetypes over the floor" do
    archetype = create(:question_archetype, canonical_prompt: "why us")
    4.times {
      archetype.answer_proposal_verdicts.create!(strategy_source: "ai", verdict: "accepted", proposed_text_sha256: sha)
    }
    archetype.answer_proposal_verdicts.create!(strategy_source: "ai", verdict: "edited", proposed_text_sha256: sha,
                                               final_text_sha256: sha, edit_distance: 20)

    report = described_class.call(floor: 5)

    row = report[:archetypes].sole
    expect(row[:verdicts]).to eq(5)
    expect(row[:by_strategy]["ai"][:acceptance_rate]).to eq(0.8)
    expect(row[:by_strategy]["ai"][:median_edit_distance]).to eq(20)
  end

  it "does not write to the database" do
    archetype = create(:question_archetype)
    5.times {
      archetype.answer_proposal_verdicts.create!(strategy_source: "ai", verdict: "accepted", proposed_text_sha256: sha)
    }

    expect { described_class.call }.not_to change(ApplicationQuestion, :count)
  end
end
